from datetime import timedelta

from clock import utcnow
from memory.service import _tokens, rank_memories, score_memory
from models import MemoryItem


def memory(
    *,
    kind: str,
    text: str,
    mention_count: int = 1,
    last_seen_at=None,
    importance: float = 0.7,
    confidence: float = 0.9,
) -> MemoryItem:
    now = utcnow()
    return MemoryItem(
        id=f"memory-{kind}-{text[:8]}",
        account_id="account-1",
        kind=kind,
        text=text,
        canonical_key=f"key-{kind}-{text[:8]}",
        source_type="conversation_message",
        source_id="message-1",
        confidence=confidence,
        importance=importance,
        mention_count=mention_count,
        first_seen_at=last_seen_at or now,
        last_seen_at=last_seen_at or now,
        created_at=last_seen_at or now,
        updated_at=last_seen_at or now,
    )


def test_ranking_prefers_content_type() -> None:
    now = utcnow()
    error = memory(kind="learning_error", text="under the tree")
    experience = memory(kind="experience", text="under the tree")

    ranked = rank_memories([experience, error], focus_context="tree", now=now)

    assert ranked[0] is error


def test_ranking_prefers_recent_memory() -> None:
    now = utcnow()
    recent = memory(kind="experience", text="under the tree", last_seen_at=now)
    old = memory(
        kind="experience",
        text="under the tree",
        last_seen_at=now - timedelta(days=365),
    )

    ranked = rank_memories([old, recent], focus_context="tree", now=now)

    assert ranked[0] is recent


def test_ranking_prefers_frequent_memory() -> None:
    now = utcnow()
    frequent = memory(kind="experience", text="under the tree", mention_count=5)
    once = memory(kind="experience", text="under the tree", mention_count=1)

    ranked = rank_memories([once, frequent], focus_context="tree", now=now)

    assert ranked[0] is frequent


def test_ranking_prefers_topic_relevance() -> None:
    now = utcnow()
    relevant = memory(kind="experience", text="under the tree")
    unrelated = memory(kind="experience", text="mint on the balcony")

    ranked = rank_memories([unrelated, relevant], focus_context="tree", now=now)

    assert ranked[0] is relevant


def test_score_uses_cjk_bigrams() -> None:
    now = utcnow()
    item = memory(kind="experience", text="在公园的树下休息")
    score = score_memory(
        item,
        query_tokens=_tokens("公园里的树"),
        now=now,
    )
    assert score > 0
