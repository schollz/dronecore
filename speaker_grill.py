import numpy as np
import matplotlib.pyplot as plt


def generate_packed_circles(container_diameter=75, circle_diameter=4, padding=1.5):
    fig, ax = plt.subplots(figsize=(8, 8))
    boundary = container_diameter / 2
    ax.set_xlim(-boundary, boundary)
    ax.set_ylim(-boundary, boundary)
    ax.set_aspect("equal")
    ax.axis("off")  # Hide axes

    radius = circle_diameter / 2
    effective_diameter = circle_diameter + 2 * padding

    # Compute grid parameters for hexagonal packing
    x_spacing = effective_diameter
    y_spacing = effective_diameter * np.sqrt(3) / 2

    placed_circles = []
    row = 0
    y = -boundary + radius + padding
    while y + radius + padding <= boundary:
        x_offset = 0 if row % 2 == 0 else x_spacing / 2
        x = -boundary + radius + padding + x_offset
        while x + radius + padding <= boundary:
            if np.hypot(x, y) + radius + padding <= boundary:
                placed_circles.append((x, y))
                ax.add_patch(plt.Circle((x, y), radius, color="black", fill=True))
            x += x_spacing
        y += y_spacing
        row += 1

    plt.show()


# Generate and display the image
generate_packed_circles()
