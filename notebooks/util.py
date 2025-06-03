import pandas as pd
import json
import matplotlib.pyplot as plt
import numpy as np
import math

def load_data(datafile):
    # load the json, and normalize into a dataframe
    with open(datafile) as f:
        df = pd.json_normalize(json.load(f), record_path=["snapshots"],
                               meta=[
                                   ["settings", "patchImprovement"],
                                   ["settings", "patchRecovery"],
                                   ["settings", "maxCost"],
                                   ["settings", "boundaryConditions"],
                                   ["settings", "numLocations"],
                                   ["settings", "randomSeedWalkers"],
                                   ["settings", "randomSeedLocations"],
                                   ["settings", "recoveryLogic"],
                                   ["settings", "improvementLogic"],
                                ])

    df["ratio"] = df["settings.patchImprovement"] / df["settings.patchRecovery"]
    # hopefully won't be necessary forever
    # df["run_id"] = [i // 201 for i in range(df.shape[0])]


    return df

def describe(df):
    print("ratios:", df["ratio"].unique())
    print("patch recovery:", df["settings.patchRecovery"].unique())
    print("max costs:", df["settings.maxCost"].unique())
    print("boundary conditions:", df["settings.boundaryConditions"].unique())
    print("num locations:", df["settings.numLocations"].unique())
    print("random walker seeds:", len(df["settings.randomSeedWalkers"].unique()))
    print("random locations seeds:", len(df["settings.randomSeedLocations"].unique()))
    print("patch recovery logic:", df["settings.recoveryLogic"].unique())


def plot_patches(df, MAX_IMAGES=32):
    IM_PER_ROW = 4

    if len(df) < MAX_IMAGES:
        MAX_IMAGES = len(df)

    fig, axs = plt.subplots(math.ceil(MAX_IMAGES / IM_PER_ROW), IM_PER_ROW)
    for i in range(MAX_IMAGES):
        ax = axs[i//IM_PER_ROW, i%IM_PER_ROW]
        ax.imshow(np.reshape(df["patches"].iloc[i], (100, 100)), cmap="inferno")
        ax.axis('off')
    plt.show()

def svd(df, plot=True):
    patches = df["patches"]

    num_observations = len(patches)
    num_features = len(patches.iloc[0])
    # observations as rows, features as columns
    A = np.reshape(patches.explode(), (num_observations, num_features)).astype(float)
    # we actually *don't* want to demean A.
    # they are already appropriately scaled and as centered as they need to be!
    # A = A - np.mean(A, axis=0)
    U, S, Vh = np.linalg.svd(A, full_matrices=False)

    # svd weight
    N = len(df)

    if plot:
        s = S**2/sum(S**2)
        plt.bar([x for x in range(N)], s[:N])
        plt.show()
        
        # plot the eigen-trails
        fig, axs = plt.subplots(2, 4)
        for i in range(8):
            ax = axs[i//4, i%4]
            ax.imshow(np.reshape(Vh[i], (100, 100)), cmap="inferno")
            ax.axis('off')
            # ax.set_title(f"{i}:, {round(s[i], 3)}")

    return U, S, Vh