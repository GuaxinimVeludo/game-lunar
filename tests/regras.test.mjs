import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { test } from 'node:test';

const require = createRequire(import.meta.url);
const Regras = require('../docs/jogo/regras.js');

test('cada partida escolhe dez perguntas e aceita sorteio controlado', () => {
  const partida = Regras.novaPartida(() => 0);
  assert.equal(partida.perguntas.length, 10);
  assert.equal(partida.perguntas[0].texto, Regras.PERGUNTAS[1].texto);
  assert.equal(partida.perguntas[0].opcoes[partida.perguntas[0].certa], Regras.PERGUNTAS[1].opcoes[0]);
});

test('embaralhar não modifica a lista original', () => {
  const original = [1, 2, 3, 4];
  const resultado = Regras.embaralhar(original, () => 0.5);
  assert.deepEqual(original, [1, 2, 3, 4]);
  assert.deepEqual([...resultado].sort(), original);
});

test('acerto vale cem pontos mais os segundos inteiros restantes', () => {
  const partida = Regras.novaPartida(() => 0);
  const respondida = Regras.responder(partida, Regras.perguntaAtual(partida).certa, 7.8);
  assert.equal(respondida.pontos, 107);
  assert.equal(respondida.acertos, 1);
  assert.equal(respondida.ultimaResposta.correta, true);
});

test('acerto no último instante vale cem pontos', () => {
  const partida = Regras.novaPartida(() => 0);
  assert.equal(Regras.pontos(Regras.responder(partida, Regras.perguntaAtual(partida).certa, 0)), 100);
});

test('resposta errada e tempo esgotado não dão pontos', () => {
  const partida = Regras.novaPartida(() => 0);
  assert.equal(Regras.pontos(Regras.responder(partida, (Regras.perguntaAtual(partida).certa + 1) % 4, 15)), 0);
  assert.equal(Regras.pontos(Regras.responder(partida, -1, 0)), 0);
});

test('segundos restantes ficam limitados entre zero e quinze', () => {
  const partida = Regras.novaPartida(() => 0);
  const certa = Regras.perguntaAtual(partida).certa;
  assert.equal(Regras.pontos(Regras.responder(partida, certa, 99)), 115);
  assert.equal(Regras.pontos(Regras.responder(partida, certa, -4)), 100);
});

test('avançar percorre as perguntas e termina na décima', () => {
  let partida = Regras.novaPartida(() => 0);
  for (let i = 0; i < 9; i++) partida = Regras.avancar(partida);
  assert.equal(partida.indice, 9);
  assert.equal(partida.terminou, false);
  partida = Regras.avancar(partida);
  assert.equal(partida.indice, 10);
  assert.equal(partida.terminou, true);
  assert.equal(Regras.perguntaAtual(partida), null);
});

test('estado encerrado ou escolha inválida não altera pontuação', () => {
  const partida = Regras.novaPartida(() => 0);
  assert.equal(Regras.responder(partida, 7, 10).pontos, 0);
  const encerrada = { ...partida, terminou: true };
  assert.equal(Regras.responder(encerrada, 0, 10), encerrada);
  assert.equal(Regras.avancar(encerrada), encerrada);
});
