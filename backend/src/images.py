from io import BytesIO

from PIL import Image, ImageOps, UnidentifiedImageError


class ImageError(Exception):
    pass


def process_image(data: bytes, max_dimension: int) -> tuple[bytes, str, int, int]:
    try:
        image = Image.open(BytesIO(data))
        image = ImageOps.exif_transpose(image)
        image = image.convert("RGB")
    except (UnidentifiedImageError, OSError, ValueError, Image.DecompressionBombError) as exc:
        raise ImageError("Invalid image.") from exc

    image.thumbnail((max_dimension, max_dimension))
    output = BytesIO()
    image.save(output, format="JPEG", quality=85, optimize=True)
    return output.getvalue(), "image/jpeg", image.width, image.height
