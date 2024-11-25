import perlin_noise

noise = perlin_noise.PerlinNoise(octaves=5)
for i in range(10):
    for j in range(10):
        print(abs(noise([i/50,i/50])) * 10)