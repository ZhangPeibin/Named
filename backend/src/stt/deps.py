from typing import Annotated

from fastapi import Depends

from stt.provider import TranscriptionProvider, get_transcription_provider

TranscriptionProviderDep = Annotated[
    TranscriptionProvider,
    Depends(get_transcription_provider),
]
