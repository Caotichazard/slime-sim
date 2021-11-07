# Slime Simulation on Compute Shader with Raylib


![Gif1](media/ComputeShader SlimeSim Min-%05d.gif)

Tudo veio da ideia desse video [aqui](https://www.youtube.com/watch?v=X-iSQQgOd1A) 

Basicamente a ideia é, você tem um agente numa posição X,Y, ele vai observar uma área a N casas de distancia e se houver um "rastro" (a analogia seria com feromonios de formigas) ele vai seguir esse mesmo caminho.

Fiz isso utilizando compute shaders para poder otimizar até o talo. Tanto que com o número máximo de agentes, com um sensor size de 5 ele roda a 30fps estável numa intel UHD620 (placa de vídeo integrada de laptop).

##### Variaveis legais de brincar

Em cada arquivo (exceto o transfer.glsl) há variáveis no topo que podem ser interessantes de se brincar com.

#### Coisas a fazer

- Exportar valores (minima ideia de como fazer)
- Brincar com o render.glsl pra deixar mais bonito
- Tentar usar alguns valores aleatórios
- Otimizar o agent.glsl (a partir de do tamanho 4 no sensor size fica abaixo de 60fps no laptop, quero começar a chegar perto do limite físico do laptop)
- Conseguir aumentar o número máximo de agentes