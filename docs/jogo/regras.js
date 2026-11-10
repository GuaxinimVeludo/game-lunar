/* Regras puras do LunarStar: quiz rápido sobre modos e estratégias de Brawl Stars. */
(function (raiz, fabrica) {
  const api = fabrica();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else raiz.Regras = api;
})(typeof window !== 'undefined' ? window : globalThis, function () {
  'use strict';

  const DURACAO_PERGUNTA = 15;
  const TOTAL_PERGUNTAS = 10;
  const PERGUNTAS = [
    { texto: 'Em Brawl Ball, qual é o objetivo principal?', opcoes: ['Marcar gols na meta rival', 'Juntar moedas pelo mapa', 'Proteger uma torre', 'Resolver um enigma'], certa: 0, explicacao: 'A equipe tenta marcar gols levando a bola até a meta adversária.' },
    { texto: 'No modo Gem Grab, o que a equipe disputa?', opcoes: ['Gemas que surgem na mina', 'Pedaços de um mapa', 'Chaves de uma porta', 'Cartas escondidas'], certa: 0, explicacao: 'As equipes coletam gemas e precisam manter a vantagem para vencer.' },
    { texto: 'Qual é a ideia central do Showdown?', opcoes: ['Ser a última pessoa ou equipe sobrevivente', 'Fazer mais gols', 'Construir uma ponte', 'Encontrar palavras secretas'], certa: 0, explicacao: 'No Showdown, sobreviver até o fim é o objetivo.' },
    { texto: 'O que costuma acontecer quando um personagem fica dentro de um arbusto?', opcoes: ['Pode ficar escondido dos adversários distantes', 'Fica invencível', 'Teleporta para a base', 'Ganha uma vida extra'], certa: 0, explicacao: 'Arbustos ajudam a esconder quem está dentro deles.' },
    { texto: 'Para que servem as paredes no mapa?', opcoes: ['Bloquear movimento e alguns disparos', 'Aumentar o cronômetro', 'Trocar o modo de jogo', 'Dar pontos automaticamente'], certa: 0, explicacao: 'Paredes são obstáculos e podem proteger jogadores de disparos.' },
    { texto: 'Em uma partida de equipes, qual atitude ajuda mais?', opcoes: ['Cooperar com a equipe e observar o objetivo', 'Ignorar o mapa inteiro', 'Ficar parado no início', 'Atacar os próprios aliados'], certa: 0, explicacao: 'Cooperação e atenção ao objetivo ajudam a equipe.' },
    { texto: 'O que uma partida com limite de tempo exige?', opcoes: ['Fazer boas escolhas antes de o tempo acabar', 'Esperar sem agir', 'Trocar de aparelho', 'Fechar o jogo no meio'], certa: 0, explicacao: 'O relógio torna importante agir com estratégia.' },
    { texto: 'Por que observar o alcance de um ataque pode ser útil?', opcoes: ['Ajuda a escolher a distância certa', 'Muda o nome do jogador', 'Abre a loja', 'Apaga os obstáculos'], certa: 0, explicacao: 'Cada ataque funciona melhor em certas distâncias.' },
    { texto: 'O que pode ajudar a evitar um disparo inimigo?', opcoes: ['Mover-se e usar a cobertura do mapa', 'Ficar sempre no mesmo lugar', 'Olhar apenas o placar', 'Desligar o som'], certa: 0, explicacao: 'Movimento e cobertura podem ajudar a escapar de ataques.' },
    { texto: 'Em modos com objetivo, o que deve guiar suas decisões?', opcoes: ['O objetivo daquele modo', 'A cor do botão', 'A tela inicial', 'O nome do aplicativo'], certa: 0, explicacao: 'Cada modo tem um objetivo: jogar em equipe em torno dele é essencial.' },
    { texto: 'Qual é uma boa razão para não perseguir alguém sem pensar?', opcoes: ['Você pode se afastar do objetivo e da equipe', 'O jogo apaga a conta', 'O mapa fica maior', 'O cronômetro para'], certa: 0, explicacao: 'Perseguir sem avaliar a situação pode deixar o objetivo desprotegido.' },
    { texto: 'Antes de começar uma partida, o que vale a pena conferir?', opcoes: ['O modo e o objetivo da partida', 'A previsão do tempo', 'A pasta de fotos', 'O idioma do teclado'], certa: 0, explicacao: 'Saber o objetivo ajuda a escolher uma estratégia.' }
  ];

  function embaralhar(itens, sorteio) {
    const aleatorio = typeof sorteio === 'function' ? sorteio : Math.random;
    const resultado = itens.slice();
    for (let i = resultado.length - 1; i > 0; i--) {
      const n = Math.max(0, Math.min(0.999999999, Number(aleatorio()) || 0));
      const j = Math.floor(n * (i + 1));
      [resultado[i], resultado[j]] = [resultado[j], resultado[i]];
    }
    return resultado;
  }

  function novaPartida(sorteio) {
    return {
      perguntas: embaralhar(PERGUNTAS, sorteio).slice(0, TOTAL_PERGUNTAS).map((pergunta) => {
        const opcoes = embaralhar(pergunta.opcoes.map((texto, indice) => ({ texto, correta: indice === pergunta.certa })), sorteio);
        return Object.assign({}, pergunta, {
          opcoes: opcoes.map((opcao) => opcao.texto),
          certa: opcoes.findIndex((opcao) => opcao.correta)
        });
      }),
      indice: 0,
      pontos: 0,
      acertos: 0,
      terminou: false
    };
  }

  function perguntaAtual(estado) {
    return estado && !estado.terminou ? estado.perguntas[estado.indice] || null : null;
  }

  function responder(estado, escolha, segundosRestantes) {
    if (!estado || estado.terminou || !perguntaAtual(estado)) return estado;
    const pergunta = perguntaAtual(estado);
    const correta = Number.isInteger(escolha) && escolha === pergunta.certa;
    const segundos = Math.max(0, Math.min(DURACAO_PERGUNTA, Math.floor(Number(segundosRestantes) || 0)));
    return Object.assign({}, estado, {
      pontos: estado.pontos + (correta ? 100 + segundos : 0),
      acertos: estado.acertos + (correta ? 1 : 0),
      ultimaResposta: { correta, explicacao: pergunta.explicacao, certa: pergunta.certa }
    });
  }

  function avancar(estado) {
    if (!estado || estado.terminou) return estado;
    const indice = estado.indice + 1;
    return Object.assign({}, estado, { indice, terminou: indice >= estado.perguntas.length });
  }

  function pontos(estado) {
    return estado && Number.isFinite(estado.pontos) ? estado.pontos : 0;
  }

  return { DURACAO_PERGUNTA, TOTAL_PERGUNTAS, PERGUNTAS, embaralhar, novaPartida, perguntaAtual, responder, avancar, pontos };
});
