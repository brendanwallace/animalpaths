import pygame

import world

# pygame setup
pygame.init()
WIDTH, HEIGHT = world.World.WIDTH, world.World.HEIGHT
FPS = 100

SCALE = 3
screen = pygame.display.set_mode((WIDTH*SCALE, HEIGHT*SCALE))
clock = pygame.time.Clock()
running = True

paused = False
adding_path = True

w = world.World()

while running:
    # poll for events
    # pygame.QUIT event means the user clicked X to close your window
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_p:
                paused = not paused
            if event.key == pygame.K_m:
                adding_path = not adding_path



    if not paused:
        w.update()
        pass
    for x in range(world.World.WIDTH):
        for y in range(world.World.HEIGHT):
            p = int(w.patches[y][x]*255)
            screen.fill((p, p, p), pygame.Rect(x*SCALE, y*SCALE, SCALE, SCALE))


    for a in w.animals:
        x, y = a.position
        x, y = x*SCALE, y*SCALE
        pygame.draw.circle(screen, "blue", pygame.Vector2((x, y)), 2)

    for l in w.locations:
        x, y = l.position
        x, y = x*SCALE, y*SCALE
        pygame.draw.circle(screen, "green", pygame.Vector2((x, y)), 1)


    #pygame.draw.circle(screen, "red", pos, 10)

    if paused:
        display_text = "paused - {}".format("adding path" if adding_path else "removing path")

        pygame.display.set_caption(display_text)
    else:
        pygame.display.set_caption("running")


    ## path editing
    if paused:
        if pygame.mouse.get_pressed()[0]:
            x, y = pygame.mouse.get_pos()
            x, y = int(x/SCALE), int(y/SCALE)

            print(x, y)
            print("adding path: ", adding_path)
            if adding_path:
                w.patches[y][x] = 1.0
            else:
                w.patches[y][x] = 0.0



    # RENDER YOUR GAME HERE

    # flip() the display to put your work on screen
    pygame.display.flip()

    clock.tick(FPS)  # limits FPS

pygame.quit()