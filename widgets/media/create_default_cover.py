"""Create default album art cover image - theme-neutral design."""
from PIL import Image, ImageDraw
from pathlib import Path


def create_default_album_cover(output_path, size=256):
    """
    Create a theme-neutral default album art cover.

    Uses grayscale colors that work with any background theme.
    Depicts a simple vinyl disc/record design.

    Args:
        output_path: Path to save the PNG file
        size: Image dimensions (square)
    """
    # Create transparent background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    center = size // 2

    # Outer disc
    disc_radius = int(size * 0.35)
    draw.ellipse(
        [center - disc_radius, center - disc_radius,
         center + disc_radius, center + disc_radius],
        fill=(80, 80, 85, 255),
        outline=(100, 100, 110, 255),
        width=2
    )

    # Concentric grooves (3 circles for vinyl look)
    for i in range(3):
        groove_radius = disc_radius - 15 - (i * 12)
        draw.ellipse(
            [center - groove_radius, center - groove_radius,
             center + groove_radius, center + groove_radius],
            outline=(60, 60, 65, 180),
            width=1
        )

    # Label area (lighter circle in center)
    label_radius = int(disc_radius * 0.4)
    draw.ellipse(
        [center - label_radius, center - label_radius,
         center + label_radius, center + label_radius],
        fill=(110, 110, 120, 255),
        outline=(130, 130, 140, 255),
        width=1
    )

    # Center hole
    hole_radius = int(disc_radius * 0.15)
    draw.ellipse(
        [center - hole_radius, center - hole_radius,
         center + hole_radius, center + hole_radius],
        fill=(40, 40, 45, 255),
        outline=(30, 30, 35, 255),
        width=2
    )

    # Save the image
    img.save(output_path, 'PNG')
    print(f"Created {output_path} ({size}x{size})")


if __name__ == "__main__":
    # Create default cover in assets directory
    assets_dir = Path(__file__).parent / "assets"
    assets_dir.mkdir(exist_ok=True)

    output_file = assets_dir / "default-cover.png"
    create_default_album_cover(output_file, size=256)
