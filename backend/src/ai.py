from config import Settings


class AINotConfigured(Exception):
    pass


def build_model(settings: Settings):
    model_id = settings.ai_model
    if model_id.startswith("deepseek:"):
        if not settings.deepseek_api_key:
            raise AINotConfigured
        from pydantic_ai.models.openai import OpenAIChatModel
        from pydantic_ai.providers.deepseek import DeepSeekProvider

        return OpenAIChatModel(
            model_id.split(":", 1)[1],
            provider=DeepSeekProvider(api_key=settings.deepseek_api_key),
        )
    if model_id.startswith("openai:"):
        if not settings.openai_api_key:
            raise AINotConfigured
        from pydantic_ai.models.openai import OpenAIChatModel
        from pydantic_ai.providers.openai import OpenAIProvider

        return OpenAIChatModel(
            model_id.split(":", 1)[1],
            provider=OpenAIProvider(api_key=settings.openai_api_key),
        )
    return model_id


def build_model_settings(settings: Settings):
    if settings.ai_model.startswith("deepseek:"):
        from pydantic_ai.models.openai import OpenAIChatModelSettings

        return OpenAIChatModelSettings(thinking=False)
    return None
