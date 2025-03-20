import numpy as np
import matplotlib.pyplot as plt


def generate_packed_circles(container_diameter=75, circle_diameter=4, padding=2):
    fig, ax = plt.subplots(figsize=(8, 8))
    boundary = container_diameter / 2
    ax.set_xlim(-boundary, boundary)
    ax.set_ylim(-boundary, boundary)
    ax.set_aspect("equal")
    ax.axis("off")  # Hide axes

    radius = circle_diameter / 2
    effective_diameter = circle_diameter + 2 * padding

    placed_circles = []

    # Start from the outermost ring and move inward
    ring_radius = boundary - radius - padding
    while ring_radius >= radius + padding:
        num_circles = int(2 * np.pi * ring_radius / effective_diameter)
        for i in range(num_circles):
            angle = (2 * np.pi / num_circles) * i
            x = ring_radius * np.cos(angle)
            y = ring_radius * np.sin(angle)
            placed_circles.append((x, y))
            ax.add_patch(plt.Circle((x, y), radius, color="black", fill=True))
        ring_radius -= effective_diameter  # Move inward by one layer

    # Always place a single circle in the center
    ax.add_patch(plt.Circle((0, 0), radius, color="black", fill=True))

    plt.show()


# Generate and display the image
# generate_packed_circles(75, 4, 2)
generate_packed_circles(75, 5, 2)
