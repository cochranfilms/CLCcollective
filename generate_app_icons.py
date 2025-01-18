from PIL import Image
import os

def resize_image(input_path, output_path, size):
    with Image.open(input_path) as img:
        # Convert to RGB if image is in RGBA mode
        if img.mode == 'RGBA':
            img = img.convert('RGB')
        # Use high-quality Lanczos resampling
        resized = img.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(output_path, 'JPEG', quality=95)
        print(f"Generated: {output_path} ({size}x{size})")

def generate_app_icons():
    # Define the source directory (where App_Logo.jpg is)
    source_dir = "CLCcollective/Assets.xcassets/AppIcon.appiconset"
    source_file = os.path.join(source_dir, "App_Logo.jpg")

    # Define all required sizes and their filenames
    icon_sizes = [
        # iPhone
        ("App_Logo-20@2x.jpg", 40),   # 20pt @2x
        ("App_Logo-20@3x.jpg", 60),   # 20pt @3x
        ("App_Logo-29@2x.jpg", 58),   # 29pt @2x
        ("App_Logo-29@3x.jpg", 87),   # 29pt @3x
        ("App_Logo-40@2x.jpg", 80),   # 40pt @2x
        ("App_Logo-40@3x.jpg", 120),  # 40pt @3x
        ("App_Logo-60@2x.jpg", 120),  # 60pt @2x
        ("App_Logo-60@3x.jpg", 180),  # 60pt @3x

        # iPad
        ("App_Logo-20.jpg", 20),      # 20pt @1x
        ("App_Logo-20@2x-1.jpg", 40), # 20pt @2x
        ("App_Logo-29.jpg", 29),      # 29pt @1x
        ("App_Logo-29@2x-1.jpg", 58), # 29pt @2x
        ("App_Logo-40.jpg", 40),      # 40pt @1x
        ("App_Logo-40@2x-1.jpg", 80), # 40pt @2x
        ("App_Logo-76.jpg", 76),      # 76pt @1x
        ("App_Logo-76@2x.jpg", 152),  # 76pt @2x
        ("App_Logo-83.5@2x.jpg", 167) # 83.5pt @2x
    ]

    # Check if source file exists
    if not os.path.exists(source_file):
        print(f"Error: Source file {source_file} not found!")
        return

    # Generate each size
    for filename, size in icon_sizes:
        output_path = os.path.join(source_dir, filename)
        resize_image(source_file, output_path, size)

    print("\nAll app icons have been generated successfully!")
    print("Note: Make sure to remove App_Logo 1.jpg and App_Logo 2.jpg if they exist.")

if __name__ == "__main__":
    generate_app_icons() 