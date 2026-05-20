import pandas as pd
import matplotlib.pyplot as plt
import os
import argparse

def plot_training_metrics(csv_path, output_path=None):
    """
    Reads a metrics CSV and plots generator and discriminator losses.
    """
    if not os.path.exists(csv_path):
        print(f"Error: File '{csv_path}' not found.")
        return

    # Load the data
    df = pd.read_csv(csv_path)
    
    # Calculate a global step (batch index) for the X-axis
    df['step'] = range(len(df))

    # Create the figure
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 10), sharex=True)

    # Top Plot: Total Generator vs Discriminator Loss
    ax1.plot(df['step'], df['loss-g'], label='Generator Loss', color='blue', alpha=0.6)
    ax1.plot(df['step'], df['loss-d'], label='Discriminator Loss', color='red', alpha=0.6)
    ax1.set_title('Generator and Discriminator Losses')
    ax1.set_ylabel('Loss')
    ax1.legend()
    ax1.grid(True, linestyle='--', alpha=0.7)

    # Bottom Plot: Discriminator Detail (Real vs Fake)
    ax2.plot(df['step'], df['loss-d-real'], label='D Loss (Real)', color='green', alpha=0.6)
    ax2.plot(df['step'], df['loss-d-fake'], label='D Loss (Fake)', color='orange', alpha=0.6)
    ax2.set_title('Discriminator Loss Components')
    ax2.set_ylabel('Loss')
    ax2.set_xlabel('Global Step (Batch)')
    ax2.legend()
    ax2.grid(True, linestyle='--', alpha=0.7)

    # Adjust layout
    plt.tight_layout()

    if output_path:
        plt.savefig(output_path)
        print(f"Metrics plot saved to: {output_path}")
    else:
        plt.show()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Plot training metrics from CSV')
    parser.add_argument('--csv', type=str, default='metrics.csv', help='Path to metrics.csv')
    parser.add_argument('--out', type=str, default='metrics_plot.png', help='Output image path')
    
    args = parser.parse_args()
    plot_training_metrics(args.csv, args.out)