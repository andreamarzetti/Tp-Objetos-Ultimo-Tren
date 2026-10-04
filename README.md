# Grupo

Nombre: **syntax error 2**

Integrantes: **Andrea Noemi Marzetti**, **COMPLETAR ACA**

# Consigna TP Integrador

Hacer un juego aplicando los conceptos de la materia.
El TP debe:

- aplicar los conceptos que vemos durante la materia.
- tener tests para las funcionalidades que definan.
- evitar la repetición de lógica.

# Como correrlo

Con la extensión de VSCode, pararse sobre el program y correr `Run Game`.

También, se puede correr desde la terminal como:

```
wollok run juego.juego --skipValidations --port 4200 -p RUTA_AL_PROYECTO
```

# Entregas

## Checkpoint 1: 05/10

Para el 05/10 debe estar subido en el repo el nombre, descripción y controles de su juego (editen este archivo en la sección **Juego** al final) y el código de lo que tengan hasta el momento.

También, se deben proponer en que van a continuar trabajando para el siguiente checkpoint.

## Checkpoint 2: 19/10

Para el 19/10 debe estar subido arreglos que se hayan pedido en el primer checkpoint y nuevos cambios.

## Entrega y corrección virtual sincrónica: 02/11

Al igual que en los tps integradores anteriores, este día se dedica a corregir los trabajos prácticos.

En esta entrega final se evaluará el uso de objetos en el tp.

# Juego: Último Tren 🚇🧟

## Descripción

Juego de plataformas en pixel art. Estalló un apocalipsis zombie en Buenos Aires y quedaste atrapada en la estación Medrano de la línea B. El último tren llega en **90 segundos**: tenés que sobrevivir hasta que llegue.

Los zombies salen sin parar de los túneles de los dos costados. Vos corrés, saltás entre las vigas, disparás y juntás los suministros que van apareciendo.

**Zombies**

| Zombie       | Velocidad  | Vida | Daño | Puntos | Especial                                  |
|--------------|------------|------|------|--------|-------------------------------------------|
| 🧟 Caminante | normal     | 2    | 1    | 10     | -                                         |
| 🏃 Corredor  | rápido     | 1    | 1    | 15     | salta para alcanzarte si estás más arriba |
| 🐷 Gordo     | lento      | 6    | 2    | 50     | al morir deja munición                    |

Si un zombie llega al lado tuyo, te ataca.

**Armas**

- 🔫 **Pistola**: daño 1, balas infinitas.
- 💥 **Escopeta**: daño 3, munición limitada. Cuando se queda sin balas, volvés a la pistola.

**Suministros** (aparecen arriba de las vigas)

- 🩹 **Botiquín**: recupera 4 de vida (máximo 10).
- 📦 **Caja de escopeta**: te equipa la escopeta con 5 balas.

**Fin del juego**: si llega el tren, ganás. Si te quedás sin vida, perdés.

## Controles

- **← →**: moverse (y apuntar hacia ese lado).
- **↑**: saltar (2 casilleros: desde el piso llegás a las vigas de los costados, y desde ahí a la viga del medio).
- **Espacio**: disparar.
- **Enter**: empezar la partida desde la pantalla de inicio.

## Checkpoint 1: qué está hecho

- Nivel armado a partir de un mapa de texto (piso y vigas).
- Física de plataformas: gravedad, salto y choque contra bloques, compartida por la sobreviviente y los zombies.
- Tres tipos de zombie con velocidad, vida, daño y comportamientos distintos (el corredor salta, el gordo deja munición).
- Dos armas con comportamiento distinto; balas que avanzan, impactan y chocan contra los bloques.
- Suministros, vida, puntos y cuenta regresiva hasta el tren.
- Eventos de teclado y temporales (reloj del juego, cuenta regresiva, oleadas y suministros).
- Pantalla de inicio con el título y los controles.
- 33 tests de la lógica de dominio.

## Ideas para el Checkpoint 2

- **Herencia y template method en los suministros**: una superclase `Suministro` cuyo `serTocadoPor` aplica el efecto (que redefine cada subclase) y después se quita del nivel. Así se elimina la lógica repetida entre Botiquín y CajaDeEscopeta.
- **Herencia en los tipos de bloque y en las armas**, para sacar la lógica repetida (`construirEn`, `disparar`).
- **Bloques nuevos**: charcos de ácido que lastiman, plataformas que se rompen, escaleras.
- **Nuevas armas**: un bate para golpear al zombie de al lado y granadas que dañan a todos los de alrededor.
- **Zombie escupidor**: ataca de lejos tirando ácido.
- **Niveles**: cada estación de la línea B es un mapa distinto (solo hay que escribir otro mapa de texto).
- **Modo cooperativo**: dos sobrevivientes en el mismo teclado (flechas y WASD), con habilidades distintas.
- **Sonidos y animaciones**: disparos, gruñidos, música de suspenso y personajes que alternan imágenes al caminar.
