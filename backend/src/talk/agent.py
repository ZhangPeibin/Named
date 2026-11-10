from functools import lru_cache
from typing import Protocol

from pydantic_ai import Agent

from ai import AINotConfigured, build_model, build_model_settings
from config import Settings, get_settings
from errors import ApiError
from talk.schemas import HelpSuggestion, TalkResponse


class TalkAgent(Protocol):
    async def respond(
        self,
        *,
        native_language: str,
        focus_context: str,
        soul_context: str,
        memory_context: str,
        error_profile_context: str,
        history: list[dict[str, str]],
        user_text: str,
    ) -> TalkResponse: ...


class AgentFailed(Exception):
    pass


SYSTEM_PROMPT = """
You are Named's English conversation partner.

Conversation style:
- Respond to the learner's meaning first.
- Reply in 1-2 short sentences, about 35 words or fewer.
- Ask exactly one question, then stop.
- Use simple, natural A2-B1 English. One idea per sentence.
- Use contractions when they sound natural.
- Use the focus word at most twice, and only when it fits naturally.
  Never force the focus word into every turn.
- Do not say "today's word", "let's practice", or explain the exercise.
- Use plain text only. Never use Markdown or bold markers.

Corrections:
- If the learner's English has a clear error, include a correction.
  Do not silently ignore it.
- Prefer one correction per turn; never return more than two.
- Prioritize errors that change meaning or affect the focus word.
- Keep `original` exactly as the learner wrote it.
- Make `suggestion` natural English, not a grammar explanation.
- Keep `note` short and in the learner's native language.
- For every correction, also return `category` and `pattern`:
  category must be one of: grammar, vocabulary, spelling, naturalness.
  Use these grammar patterns when applicable: third_person_s, articles,
  prepositions, verb_tense, verb_form, subject_verb_agreement, plural,
  word_order, pronouns, comparatives, modal_verbs, other_grammar.
  Use these vocabulary patterns: word_choice, collocation, word_form,
  other_vocabulary. Use spelling for spelling. Use awkward_phrasing,
  redundancy, register, or other_naturalness for naturalness.
- Small spelling errors are still errors. Use a compact note such as
  "Ilt → It; framewor → framework" instead of a long explanation.
- Do not invent corrections when the learner's English is already natural.
- If an error is ambiguous, ask a clarification question instead of guessing.

Output fields:
- reply: the assistant message in English. Plain text only.
- native_reply: a faithful translation of reply into the learner's native
  language. Keep the same meaning and do not add facts. Leave this null when the
  learner's native language is English.
- corrections: zero, one, or two corrections following the rules above.
- annotations: 1-2 useful words, chunks, or grammar points from the reply.
  Use kind "word", "expression", or "grammar". `text` must be copied exactly
  from the reply. Prefer language the learner may not know, or an opaque use
  that is easy to miss; do not annotate obvious words.
  For a word, set `part_of_speech` (for example "adv.") and put the short
  Chinese meaning in `meaning_zh`. Also include pronunciation for a word:
  `ipa` in slashes, `syllables`, `vowels` (vowel sounds), `consonants`
  (consonant sounds), and `phonics` (a short letter-sound or spelling hint in
  Chinese). Example: "Drink it plain" -> text "plain", part_of_speech "adv.",
  meaning_zh "不加其他东西地；直接地", ipa "/pleɪn/", syllables "plain",
  vowels ["/eɪ/"], consonants ["/p/", "/l/", "/n/"],
  phonics "ai 发 /eɪ/；结尾的 n 要轻轻收住".
  Leave pronunciation fields empty for grammar and expression annotations.
  For grammar, put the reusable pattern in `grammar`, for example
  "pour + 液体 + from + 容器", and the concise Chinese explanation in
  `meaning_zh`, for example "从容器里倒出液体".
- memories: zero to three durable facts or learning signals explicitly provided
  by the learner in this turn. Use one of: identity, learning_error, word,
  expression, experience, topic, preference. Keep each item short and in the
  learner's own language or plain English. Do not include AI examples, guesses,
  or facts from earlier turns.
- suggested_expressions: optional expressions the learner could reuse later.
- needs_confirmation: true only when you cannot understand the learner and need
  them to clarify.

Do not invent personal facts, places, people, or feelings the learner did not
provide. Do not infer age, gender, English level, interests, or life experiences.
""".strip()


class PydanticAITalkAgent:
    def __init__(self, settings: Settings) -> None:
        self._agent = Agent(
            build_model(settings),
            output_type=TalkResponse,
            system_prompt=SYSTEM_PROMPT,
            model_settings=build_model_settings(settings),
        )

    async def respond(
        self,
        *,
        native_language: str,
        focus_context: str,
        soul_context: str,
        memory_context: str,
        error_profile_context: str,
        history: list[dict[str, str]],
        user_text: str,
    ) -> TalkResponse:
        transcript = "\n".join(f"{message['role']}: {message['text']}" for message in history)
        prompt = (
            f"Learner native language: {native_language}\n"
            f"Current focus:\n{focus_context}\n\n"
            f"Known Soul context:\n{soul_context or '(none)'}\n\n"
            f"Relevant learner memories (use only when relevant; do not mention "
            f"this list or claim perfect memory):\n{memory_context or '(none)'}\n\n"
            f"Known recurring learner errors (use only when relevant; never "
            f"mention this list or label the learner):\n"
            f"{error_profile_context or '(none)'}\n\n"
            f"Conversation so far:\n{transcript or '(new conversation)'}\n\n"
            f"New learner message: {user_text}"
        )
        try:
            result = await self._agent.run(prompt)
        except Exception as exc:
            raise AgentFailed(str(exc)) from exc
        return result.output


@lru_cache
def get_talk_agent() -> TalkAgent:
    settings = get_settings()
    try:
        return PydanticAITalkAgent(settings)
    except AINotConfigured as exc:
        raise ApiError(
            "AI provider is not configured.",
            status_code=503,
            code="ai_not_configured",
        ) from exc


class HelpAgent(Protocol):
    async def suggest(
        self,
        *,
        native_language: str,
        focus_context: str,
        soul_context: str,
        memory_context: str,
        error_profile_context: str,
        history: list[dict[str, str]],
        user_text: str,
    ) -> HelpSuggestion: ...


HELP_PROMPT = """
You are Named's expression helper for an English learning app.

The learner wants to say one thing in English. They may write in Chinese, in
another native language, or in imperfect English.

Return one structured suggestion:
- natural_english: one natural English sentence, preserving the learner's meaning.
  Use simple A2-B1 English and do not add facts, places, people, or feelings.
- note: optional short explanation in the learner's native language. Only include
  it when it helps them understand a better word or structure.
- alternatives: optional, at most one other natural phrasing. Do not return a
  list of variants.

Rules:
- Do not answer the learner's thought or ask a follow-up question.
- Do not create a conversational reply.
- For non-English input, this is a natural English version, not a correction.
- For English input, improve it only when there is a clear error or an obviously
  unnatural phrase. If it is already natural, return it unchanged.
- Use the current focus and recent conversation only to choose relevant wording.
- Use plain text only. Never use Markdown.
""".strip()


class PydanticAIHelpAgent:
    def __init__(self, settings: Settings) -> None:
        self._agent = Agent(
            build_model(settings),
            output_type=HelpSuggestion,
            system_prompt=HELP_PROMPT,
            model_settings=build_model_settings(settings),
        )

    async def suggest(
        self,
        *,
        native_language: str,
        focus_context: str,
        soul_context: str,
        memory_context: str,
        error_profile_context: str,
        history: list[dict[str, str]],
        user_text: str,
    ) -> HelpSuggestion:
        transcript = "\n".join(f"{message['role']}: {message['text']}" for message in history)
        prompt = (
            f"Learner native language: {native_language}\n"
            f"Current focus:\n{focus_context}\n\n"
            f"Known Soul context:\n{soul_context or '(none)'}\n\n"
            f"Relevant learner memories (use only when relevant; do not mention "
            f"this list):\n{memory_context or '(none)'}\n\n"
            f"Known recurring learner errors (use only when relevant; do not "
            f"mention this list):\n{error_profile_context or '(none)'}\n\n"
            f"Conversation so far:\n{transcript or '(new conversation)'}\n\n"
            f"Learner wants to say: {user_text}"
        )
        try:
            result = await self._agent.run(prompt)
        except Exception as exc:
            raise AgentFailed(str(exc)) from exc
        return result.output


@lru_cache
def get_help_agent() -> HelpAgent:
    settings = get_settings()
    try:
        return PydanticAIHelpAgent(settings)
    except AINotConfigured as exc:
        raise ApiError(
            "AI provider is not configured.",
            status_code=503,
            code="ai_not_configured",
        ) from exc
