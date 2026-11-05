from typing import Annotated

from fastapi import Depends

from config import Settings, get_settings
from media import MediaStore, get_media_store
from tts.provider import TTSProvider, get_tts_provider
from tts.service import SpeechAudioService, WordAudioService

SettingsDep = Annotated[Settings, Depends(get_settings)]
TTSProviderDep = Annotated[TTSProvider, Depends(get_tts_provider)]
MediaStoreDep = Annotated[MediaStore, Depends(get_media_store)]


def get_word_audio_service(
    settings: SettingsDep,
    provider: TTSProviderDep,
    store: MediaStoreDep,
) -> WordAudioService:
    return WordAudioService(settings, provider, store)


WordAudioServiceDep = Annotated[WordAudioService, Depends(get_word_audio_service)]


def get_speech_audio_service(
    settings: SettingsDep,
    provider: TTSProviderDep,
    store: MediaStoreDep,
) -> SpeechAudioService:
    return SpeechAudioService(settings, provider, store)


SpeechAudioServiceDep = Annotated[SpeechAudioService, Depends(get_speech_audio_service)]
