import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation


from paths import scenario

FRAMES = 1000
DEFAULT_UPF = 2
FPS = 30
FIGSIZE = (4, 4)
FONT_SIZE = 10

SHOW_HISTOGRAM = False
SHOW_TRIP_COST_AVERAGE = False
SHOW_PATCH_SUMS = False

HISTOGRAM_BINS = 20

FOLDER='animations/'

def animation_describe(upf):
	return f'fps:{FPS}, upf:{upf}'

def _animation_describe(upf):
	return animation_describe(upf).replace(' ', '')


def animate(s, upf=DEFAULT_UPF, folder=FOLDER, save_gif=False):
	show_live = not save_gif

	num_plots = 1
	figsize = FIGSIZE

	if SHOW_HISTOGRAM or SHOW_TRIP_COST_AVERAGE or SHOW_PATCH_SUMS:
		num_plots = 2
		width, height = figsize
		width *= 2
		figsize = (width, height)




	fig, axs = plt.subplots(1, num_plots, figsize=figsize, squeeze=False)
	fig.suptitle(s.describe())

	sim_ax = axs[0][0]
	if SHOW_HISTOGRAM:
		def draw_hist():
			axs[0][1].cla()
			axs[0][1].hist(s.world.patches.flatten(), bins=HISTOGRAM_BINS, range=(0, 1))
			axs[0][1].set_ylim((0, 4000))
			#axs[0][1].set_yscale('log')

	if SHOW_TRIP_COST_AVERAGE:
		trip_cost_averages = []
		trip_cost_plot = axs[0][1].plot(trip_cost_averages)[0]
		axs[0][1].set_xlim((0, FRAMES))
		axs[0][1].set_ylim((0, 400.0))

	if SHOW_PATCH_SUMS:
		patch_sums = []
		patch_sums_plot = axs[0][1].plot(patch_sums)[0]
		axs[0][1].set_xlim((0, FRAMES))
		axs[0][1].set_ylim((0, 10000))

	patches_imshow = sim_ax.imshow(s.world.patches.T, origin="lower", vmin=0, vmax=1)
	animal_scatter = sim_ax.scatter(
		[a.position[0] for a in s.animals],
		[a.position[1] for a in s.animals],
		s=2)
	location_scatter = sim_ax.scatter(
		[l.position[0] for l in s.locations],
		[l.position[1] for l in s.locations], s=5)

	if SHOW_HISTOGRAM:
		draw_hist()

	# prevents the scatter plots from being wider than the imshow and making
	# white space
	sim_ax.set_xlim(0, s.world.width)
	sim_ax.set_ylim(0, s.world.height)


	sim_ax.text(0, scenario.HEIGHT, animation_describe(upf), color='white', verticalalignment='top')
	sim_ax.text(0, 0, s.world.describe(), color='white', fontsize=FONT_SIZE)
	frame_text = sim_ax.text(scenario.WIDTH, 0, "0", color="white", fontsize=FONT_SIZE, horizontalalignment='right')


	def update(frame):
		print(f'frame: {frame}/{FRAMES}\r', end='')
		for _ in range(upf):
			s.update()
		patches_imshow.set_data(s.world.patches)
		animal_scatter.set_offsets(np.array([a.position for a in s.animals]))
		location_scatter.set_offsets(np.array([l.position for l in s.locations]))
		frame_text.set_text(f'{frame}')

		# updating the histogram is more annoying
		if SHOW_HISTOGRAM:
			draw_hist()

		if SHOW_TRIP_COST_AVERAGE:
			trip_cost_averages.append(s.trip_cost_average)
			trip_cost_plot.set_xdata([i for i in range(len(trip_cost_averages))])
			trip_cost_plot.set_ydata(trip_cost_averages)

		if SHOW_PATCH_SUMS:
			patch_sums.append(s.world.patches.sum())
			patch_sums_plot.set_xdata([i for i in range(len(patch_sums))])
			patch_sums_plot.set_ydata(patch_sums)



	ani = animation.FuncAnimation(fig=fig, func=update, frames=FRAMES, interval=1.0/FPS, repeat=False)

	fileroot=f'{s._describe()}|{s.world._describe()}|{_animation_describe(upf)}'

		
	if show_live:
		plt.show()

	if save_gif:
		filename = folder + fileroot
		if SHOW_HISTOGRAM:
			filename += "|hist"
		filename += ".gif"
		print("saving file as " + filename)
		ani.save(filename, writer=animation.PillowWriter(fps=FPS))
		print("animation saved")


def main():
	animate(s=scenario.RandomFixedLocations(), upf=2, folder="animations/GE/", save_gif=True)



main()
#profile()
