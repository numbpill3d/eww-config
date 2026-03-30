
from PIL import Image

def get_char(pixel, invert_colors=False):
    if invert_colors:
        # Invert grayscale value: 0 (black) becomes 255 (white), 255 (white) becomes 0 (black)
        # Then map to characters, so darker pixels get lighter chars
        if pixel > 220: return ' '  # Was white, now dark background
        if pixel > 180: return '.'
        if pixel > 150: return ':'
        if pixel > 120: return '-'
        if pixel > 90:  return '='
        if pixel > 60:  return '+'
        if pixel > 30:  return '*'
        return '#' # Was black, now bright foreground
    else:
        # Original logic: darker pixels get darker chars
        if pixel > 220: return '#'
        if pixel > 180: return '*'
        if pixel > 150: return '+'
        if pixel > 120: return '='
        if pixel > 90:  return '-'
        if pixel > 60:  return ':'
        if pixel > 30:  return '.'
        return ' '

def image_to_ascii(image_path, new_width=100, invert_colors=True):
    try:
        img = Image.open(image_path).convert('L') # Convert to grayscale
    except FileNotFoundError:
        return "ERROR: Image not found."
    except Exception as e:
        return f"ERROR: Could not process image: {e}"

    width, height = img.size
    aspect_ratio = height / width
    new_height = int(new_width * aspect_ratio * 0.55) # Adjust for character aspect ratio

    img = img.resize((new_width, new_height))
    pixels = img.getdata()

    ascii_str = ""
    for pixel_index in range(len(pixels)):
        ascii_str += get_char(pixels[pixel_index], invert_colors)
        if (pixel_index + 1) % new_width == 0:
            ascii_str += "\n"
    return ascii_str

if __name__ == '__main__':
    import sys
    if len(sys.argv) < 2:
        print("Usage: python3 img_to_ascii.py <image_path> [output_width]")
        sys.exit(1)

    image_path = sys.argv[1]
    output_width = int(sys.argv[2]) if len(sys.argv) > 2 else 100

    ascii_art = image_to_ascii(image_path, new_width=output_width, invert_colors=True)
    print(ascii_art)
