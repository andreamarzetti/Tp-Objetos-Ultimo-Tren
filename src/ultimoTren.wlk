import wollok.game.*

// =====================================================================
//  NIVEL: se arma a partir de un mapa de texto
//    "#" = piso del andén     "=" = viga metálica     " " = vacío
//  La fila de más arriba de la pantalla (y = 8) es para el marcador.
// =====================================================================
object nivel {
  const mapa = [
    "              ",   // y = 7
    "              ",   // y = 6
    "              ",   // y = 5
    "    ======    ",   // y = 4   viga del medio: se llega saltando desde las laterales
    "              ",   // y = 3
    " ===      === ",   // y = 2   vigas laterales: se llega saltando desde el piso
    "              ",   // y = 1   (las columnas 0 y 13 quedan libres para los túneles)
    "##############"    // y = 0
  ]
  const tiposDeBloque = [pisoDeAnden, viga, vacio]
  const property bloques = []
  // Grilla con el tipo de bloque de cada casillero, rodeada por un marco de límites:
  // casilleros.get(y + 1).get(x + 1) es el tipo de la posición (x, y).
  // Se arma una sola vez, así saber si un casillero está libre es inmediato
  // (antes se recorrían todos los bloques comparando posiciones, y eso hacía lento al juego).
  // Como todo se mueve de a un casillero, nada pasa más allá del marco.
  var casilleros = []

  method ancho() = 14
  method alto() = 9

  method construir() {
    const marco = (-1 .. self.ancho()).map({ x => limite })
    const filas = mapa.reverse().map({ fila =>
      [limite] + (0 .. self.ancho() - 1).map({ x => self.tipoDeBloque(fila.charAt(x)) }) + [limite]
    })
    casilleros = [marco] + filas + [marco]
    (0 .. mapa.size() - 1).forEach({ y =>
      (0 .. self.ancho() - 1).forEach({ x => self.tipoEn(game.at(x, y)).construirEn(game.at(x, y)) })
    })
  }

  method tipoDeBloque(simbolo) = tiposDeBloque.find({ tipo => tipo.simbolo() == simbolo })

  method tipoEn(posicion) = casilleros.get(posicion.y() + 1).get(posicion.x() + 1)

  method agregarBloque(bloque) {
    bloques.add(bloque)
    game.addVisual(bloque)
  }

  method hayBloqueEn(posicion) = self.tipoEn(posicion).esSolido()

  method estaLibre(posicion) = not self.hayBloqueEn(posicion)

  method estaApoyado(cuerpo) = not self.estaLibre(cuerpo.position().down(1))

  method distancia(desde, hasta) = (desde.x() - hasta.x()).abs() + (desde.y() - hasta.y()).abs()

  // Los zombies salen de los túneles de los costados
  method puntoDeAparicion() = [game.at(0, 1), game.at(self.ancho() - 1, 1)].anyOne()

  // Los suministros aparecen arriba de las vigas
  method lugarParaSuministros() =
    bloques.filter({ bloque => bloque.tipo() == viga }).map({ bloque => bloque.position().up(1) }).anyOne()
}

// Tipos de bloque (polimórficos: entienden simbolo(), esSolido() y construirEn(posicion))
object pisoDeAnden {
  method simbolo() = "#"
  method image() = "piso.png"
  method esSolido() = true
  method construirEn(posicion) { nivel.agregarBloque(new Bloque(position = posicion, tipo = self)) }
}

object viga {
  method simbolo() = "="
  method image() = "viga.png"
  method esSolido() = true
  method construirEn(posicion) { nivel.agregarBloque(new Bloque(position = posicion, tipo = self)) }
}

object vacio {
  method simbolo() = " "
  method esSolido() = false                 // por un lugar vacío se puede pasar
  method construirEn(posicion) { }          // en un lugar vacío no se construye nada
}

object limite {                             // el borde de la pantalla: no está en el mapa, solo frena
  method esSolido() = true
}

class Bloque {
  const property position
  const property tipo
  const property image = tipo.image()      // se guarda al construirlo: el juego la pide en cada frame
}

// =====================================================================
//  FÍSICA: gravedad y salto, compartida por la sobreviviente y los zombies.
//  Un "cuerpo" es cualquier objeto que entienda position e impulso.
// =====================================================================
object fisica {
  method fuerzaDeSalto() = 2

  method saltar(cuerpo) {
    if (nivel.estaApoyado(cuerpo)) cuerpo.impulso(self.fuerzaDeSalto())
  }

  method actualizar(cuerpo) {
    if (cuerpo.impulso() > 0) self.subir(cuerpo) else self.caer(cuerpo)
  }

  method subir(cuerpo) {
    const destino = cuerpo.position().up(1)
    if (nivel.estaLibre(destino)) {
      cuerpo.position(destino)
      cuerpo.impulso(cuerpo.impulso() - 1)
    } else {
      cuerpo.impulso(0)                     // se golpeó la cabeza contra un bloque
    }
  }

  method caer(cuerpo) {
    if (not nivel.estaApoyado(cuerpo)) cuerpo.position(cuerpo.position().down(1))
  }
}

// =====================================================================
//  DIRECCIONES (polimórficas: entienden siguiente y sufijo)
// =====================================================================
object izquierda {
  method siguiente(posicion) = posicion.left(1)
  method sufijo() = "izq"
}

object derecha {
  method siguiente(posicion) = posicion.right(1)
  method sufijo() = "der"
}

// =====================================================================
//  SOBREVIVIENTE
// =====================================================================
object sobreviviente {
  var property position = game.at(6, 1)
  var property impulso = 0
  var vida = 10
  var orientacion = derecha
  var arma = pistola

  method image() = "sobreviviente" + self.aspecto() + "-" + orientacion.sufijo() + ".png"
  method aspecto() = if (self.estaHerida()) "-herida" else ""

  method vida() = vida
  method vidaMaxima() = 10
  method estaViva() = vida > 0
  method estaHerida() = vida <= 3
  method orientacion() = orientacion
  method arma() = arma

  method mover(direccion) {
    orientacion = direccion
    const destino = direccion.siguiente(position)
    if (nivel.estaLibre(destino)) position = destino
  }

  method saltar() { fisica.saltar(self) }
  method disparar() { arma.disparar(self) }
  method equipar(nuevaArma) { arma = nuevaArma }

  method lanzarBala(danio) {
    partida.agregarBala(new Bala(position = position, direccion = orientacion, danio = danio))
  }

  method recibirAtaque(danio) { vida = (vida - danio).max(0) }
  method curarse(cantidad) { vida = (vida + cantidad).min(self.vidaMaxima()) }
}

// =====================================================================
//  ARMAS (polimórficas: entienden nombre() y disparar(tirador))
// =====================================================================
object pistola {
  method nombre() = "pistola"
  method danio() = 1
  method disparar(tirador) { tirador.lanzarBala(self.danio()) }   // balas infinitas
}

object escopeta {
  var municion = 0

  method nombre() = "escopeta (" + municion + ")"
  method municion() = municion
  method danio() = 3
  method recargar(cantidad) { municion = municion + cantidad }

  method disparar(tirador) {
    tirador.lanzarBala(self.danio())
    municion = municion - 1
    if (municion == 0) tirador.equipar(pistola)                 // sin balas, vuelve a la pistola
  }
}

class Bala {
  var property position
  const direccion
  const property danio

  method image() = "bala.png"
  method avanzar() { position = direccion.siguiente(position) }
  method chocoConAlgo() = not nivel.estaLibre(position)
}

// =====================================================================
//  ZOMBIES
//  La clase Zombie tiene la lógica común. Lo que cambia es su TIPO,
//  que es polimórfico: velocidad, vida, daño, puntos, si salta y qué pasa al morir.
// =====================================================================
class Zombie {
  var property position
  var property impulso = 0
  const property tipo
  var vida = 0
  var ticks = 0
  var orientacion = izquierda

  method initialize() { vida = tipo.vidaInicial() }

  method image() = tipo.nombre() + "-" + orientacion.sufijo() + ".png"
  method vida() = vida
  method estaVivo() = vida > 0
  method recibirDanio(danio) { vida = (vida - danio).max(0) }

  method actuar(objetivo) {
    ticks = ticks + 1
    if (ticks % tipo.ticksPorAccion() == 0) self.atacarOAvanzar(objetivo)
  }

  method atacarOAvanzar(objetivo) {
    if (self.estaAlLadoDe(objetivo)) {
      objetivo.recibirAtaque(tipo.danio())
    } else {
      tipo.antesDeAvanzar(self, objetivo)
      self.avanzarHacia(objetivo)
    }
  }

  method avanzarHacia(objetivo) {
    orientacion = self.direccionHacia(objetivo)
    const destino = orientacion.siguiente(position)
    if (nivel.estaLibre(destino)) position = destino
  }

  method direccionHacia(objetivo) = if (objetivo.position().x() < position.x()) izquierda else derecha
  method estaAlLadoDe(objetivo) = nivel.distancia(position, objetivo.position()) <= 1
  method estaMasAbajoQue(objetivo) = position.y() < objetivo.position().y()
  method saltar() { fisica.saltar(self) }
}

object caminante {          // equilibrado
  method nombre() = "zombie-caminante"
  method vidaInicial() = 2
  method danio() = 1
  method ticksPorAccion() = 6
  method puntos() = 10
  method antesDeAvanzar(zombie, objetivo) { }
  method alMorir(zombie) { }
}

object corredor {           // rápido y frágil; si estás más arriba, salta para alcanzarte
  method nombre() = "zombie-corredor"
  method vidaInicial() = 1
  method danio() = 1
  method ticksPorAccion() = 4
  method puntos() = 15
  method antesDeAvanzar(zombie, objetivo) {
    if (zombie.estaMasAbajoQue(objetivo)) zombie.saltar()
  }
  method alMorir(zombie) { }
}

object gordo {              // lento, resistente, pega fuerte y deja munición al morir
  method nombre() = "zombie-gordo"
  method vidaInicial() = 6
  method danio() = 2
  method ticksPorAccion() = 10
  method puntos() = 50
  method antesDeAvanzar(zombie, objetivo) { }
  method alMorir(zombie) {
    partida.agregarElemento(new CajaDeEscopeta(position = zombie.position()))
  }
}

// =====================================================================
//  SUMINISTROS (polimórficos: entienden serTocadoPor)
// =====================================================================
class Botiquin {
  const property position
  method image() = "botiquin.png"
  method serTocadoPor(personaje) {
    personaje.curarse(4)
    partida.quitarElemento(self)
  }
}

class CajaDeEscopeta {
  const property position
  method image() = "escopeta.png"
  method serTocadoPor(personaje) {
    escopeta.recargar(5)
    personaje.equipar(escopeta)
    partida.quitarElemento(self)
  }
}

// Fábricas (polimórficas: entienden crear)
object fabricaDeBotiquines { method crear(posicion) = new Botiquin(position = posicion) }
object fabricaDeEscopetas  { method crear(posicion) = new CajaDeEscopeta(position = posicion) }

// =====================================================================
//  ESTADOS DE LA PARTIDA (polimórficos)
// =====================================================================
object enPortada {
  method permiteJugar() = false
  method posicionDelTren() = game.at(-20, 1)
  method posicionDeLaPortada() = game.at(0, 0)        // la portada tapa la pantalla
  method texto() = ""
  method alComenzar() = enCurso
}

object enCurso {
  method alComenzar() = self
  method permiteJugar() = true
  method posicionDelTren() = game.at(-20, 1)          // todavía no llegó: fuera de la pantalla
  method posicionDeLaPortada() = game.at(-20, 0)      // la portada se corre fuera de la pantalla
  method texto() =
    "Vida: " + sobreviviente.vida() + "/" + sobreviviente.vidaMaxima() +
    "  |  Arma: " + sobreviviente.arma().nombre() +
    "  |  Puntos: " + partida.puntos() +
    "  |  Tren en: " + partida.segundosParaElTren() + "s"
}

object ganada {
  method alComenzar() = self
  method permiteJugar() = false
  method posicionDelTren() = game.at(0, 1)
  method posicionDeLaPortada() = game.at(-20, 0)
  method texto() = "¡LLEGÓ EL TREN! Sobreviviste con " + partida.puntos() + " puntos"
}

object perdida {
  method alComenzar() = self
  method permiteJugar() = false
  method posicionDelTren() = game.at(-20, 1)
  method posicionDeLaPortada() = game.at(-20, 0)
  method texto() = "Te alcanzaron... Eliminaste " + partida.eliminados() + " zombies"
}

// =====================================================================
//  PARTIDA: coordina todo
// =====================================================================
object partida {
  const property zombies = []
  const property elementos = []
  const property balas = []
  const tiposDeZombie = [caminante, caminante, corredor, corredor, gordo]
  const fabricas = [fabricaDeBotiquines, fabricaDeEscopetas]
  var estado = enPortada
  var puntos = 0
  var eliminados = 0
  var segundosParaElTren = 90

  method estado() = estado
  method puntos() = puntos
  method eliminados() = eliminados
  method segundosParaElTren() = segundosParaElTren
  method ganar() { estado = ganada }

  method comenzar() {
    estado = estado.alComenzar()            // solo la portada pasa a "en curso"
  }

  method iniciar() {
    game.addVisual(tren)                     // primero, así queda detrás de todo
    nivel.construir()
    game.addVisual(new Tunel(position = game.at(0, 1)))
    game.addVisual(new Tunel(position = game.at(nivel.ancho() - 1, 1)))
    self.agregarElemento(new Botiquin(position = game.at(1, 3)))
    self.agregarElemento(new CajaDeEscopeta(position = game.at(12, 3)))
    game.addVisual(sobreviviente)
    game.addVisual(marcador)
    game.addVisual(portada)                  // último, así queda arriba de todo
  }

  // ---- acciones de la jugadora ----
  method moverSobreviviente(direccion) {
    if (estado.permiteJugar()) {
      sobreviviente.mover(direccion)
      self.recogerSuministros()
    }
  }

  method saltar() {
    if (estado.permiteJugar()) sobreviviente.saltar()
  }

  method disparar() {
    if (estado.permiteJugar()) sobreviviente.disparar()
  }

  // ---- reloj del juego (cada 150 ms) ----
  method tick() {
    if (estado.permiteJugar()) {
      fisica.actualizar(sobreviviente)
      self.recogerSuministros()
      zombies.forEach({ zombie => fisica.actualizar(zombie) })
      self.moverBalas()
      self.resolverImpactos()
      zombies.forEach({ zombie => zombie.actuar(sobreviviente) })
      self.resolverImpactos()
      if (not sobreviviente.estaViva()) estado = perdida
    }
  }

  method recogerSuministros() {
    self.elementosEn(sobreviviente.position()).forEach({ elemento => elemento.serTocadoPor(sobreviviente) })
  }

  method moverBalas() {
    balas.forEach({ bala => bala.avanzar() })
    balas.filter({ bala => bala.chocoConAlgo() }).forEach({ bala => self.quitarBala(bala) })
  }

  method resolverImpactos() {
    balas.copy().forEach({ bala => self.impactar(bala) })
  }

  method impactar(bala) {
    const alcanzados = self.zombiesEn(bala.position())
    if (not alcanzados.isEmpty()) {
      alcanzados.first().recibirDanio(bala.danio())
      self.quitarBala(bala)
      self.retirarMuertos()
    }
  }

  method retirarMuertos() {
    zombies.filter({ zombie => not zombie.estaVivo() }).forEach({ zombie => self.eliminar(zombie) })
  }

  method eliminar(zombie) {
    zombies.remove(zombie)
    self.quitarVisual(zombie)
    eliminados = eliminados + 1
    puntos = puntos + zombie.tipo().puntos()
    zombie.tipo().alMorir(zombie)
  }

  // ---- eventos temporales ----
  method pasarSegundo() {
    if (estado.permiteJugar()) {
      segundosParaElTren = segundosParaElTren - 1
      if (segundosParaElTren == 0) self.ganar()
    }
  }

  method aparecerZombie() {
    if (estado.permiteJugar() and zombies.size() < 12)
      self.agregarZombie(new Zombie(position = nivel.puntoDeAparicion(), tipo = tiposDeZombie.anyOne()))
  }

  method aparecerSuministro() {
    if (estado.permiteJugar() and elementos.size() < 3)
      self.agregarElemento(fabricas.anyOne().crear(nivel.lugarParaSuministros()))
  }

  // ---- colecciones y visuales ----
  method zombiesEn(posicion) = zombies.filter({ zombie => zombie.position() == posicion })
  method elementosEn(posicion) = elementos.filter({ elemento => elemento.position() == posicion })

  method agregarZombie(zombie) {
    zombies.add(zombie)
    game.addVisual(zombie)
  }

  method agregarElemento(elemento) {
    elementos.add(elemento)
    game.addVisual(elemento)
  }

  method agregarBala(bala) {
    balas.add(bala)
    game.addVisual(bala)
  }

  method quitarElemento(elemento) {
    elementos.remove(elemento)
    self.quitarVisual(elemento)
  }

  method quitarBala(bala) {
    balas.remove(bala)
    self.quitarVisual(bala)
  }

  method quitarVisual(visual) {
    if (game.hasVisual(visual)) game.removeVisual(visual)
  }
}

// =====================================================================
//  DECORACIÓN Y MARCADOR
// =====================================================================
class Tunel {
  const property position
  method image() = "tunel.png"
}

object tren {
  method position() = partida.estado().posicionDelTren()
  method image() = "tren.png"
}

object portada {
  method position() = partida.estado().posicionDeLaPortada()
  method image() = "portada.png"
}

object marcador {
  method position() = game.at(4, nivel.alto() - 1)
  method text() = partida.estado().texto()
}
