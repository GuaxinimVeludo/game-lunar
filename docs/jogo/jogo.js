/* Interface do LunarStar: telas acessíveis, entrada por toque, mouse e teclas 1–4. */
(async function () {
  'use strict';

  const config = window.JOGO_CONFIG || {};
  const $ = (id) => document.getElementById(id);
  document.title = config.nome || 'LunarStar';
  $('titulo').textContent = config.nome || 'LunarStar';
  if (config.cor) {
    document.documentElement.style.setProperty('--cor', config.cor);
    document.querySelector('meta[name="theme-color"]').setAttribute('content', config.cor);
  }

  PlacarUI.montar($('painel-placar'));
  const progresso = await Placar.iniciar();
  $('melhor').textContent = progresso.melhor;
  Placar.aoMudar((novo) => { $('melhor').textContent = novo.melhor; });

  const LETRAS = ['A', 'B', 'C', 'D'];
  let estado = null;
  let inicioPergunta = 0;
  let intervalo = null;
  let proximoTempo = null;
  let bloqueado = false;
  let finalizando = false;

  function mostrar(tela) {
    ['tela-inicio', 'tela-jogo', 'tela-fim'].forEach((id) => { $(id).hidden = id !== tela; });
  }

  function atualizarRelogio() {
    if (!estado || estado.terminou || bloqueado) return;
    const decorrido = (performance.now() - inicioPergunta) / 1000;
    const restante = Math.max(0, Regras.DURACAO_PERGUNTA - decorrido);
    $('tempo').textContent = String(Math.ceil(restante));
    $('barra-tempo').style.width = (restante / Regras.DURACAO_PERGUNTA * 100) + '%';
    if (restante <= 0) responder(-1, 0);
  }

  function desenharPergunta() {
    const pergunta = Regras.perguntaAtual(estado);
    if (!pergunta) return finalizar();
    bloqueado = false;
    $('numero-pergunta').textContent = 'Pergunta ' + (estado.indice + 1) + '/' + estado.perguntas.length;
    $('pontos').textContent = Regras.pontos(estado);
    $('pergunta').textContent = pergunta.texto;
    $('feedback').textContent = '';
    $('opcoes').replaceChildren();
    pergunta.opcoes.forEach((texto, indice) => {
      const botao = document.createElement('button');
      botao.className = 'opcao';
      botao.type = 'button';
      const letra = document.createElement('span');
      letra.className = 'letra';
      letra.textContent = LETRAS[indice];
      const resposta = document.createElement('span');
      resposta.textContent = texto;
      botao.append(letra, resposta);
      botao.addEventListener('click', () => responder(indice));
      $('opcoes').append(botao);
    });
    inicioPergunta = performance.now();
    atualizarRelogio();
  }

  function responder(escolha, segundosForcados) {
    if (!estado || estado.terminou || bloqueado) return;
    bloqueado = true;
    const segundos = segundosForcados === undefined
      ? Math.floor(Math.max(0, Regras.DURACAO_PERGUNTA - (performance.now() - inicioPergunta) / 1000))
      : segundosForcados;
    estado = Regras.responder(estado, escolha, segundos);
    $('pontos').textContent = Regras.pontos(estado);
    const resposta = estado.ultimaResposta;
    const pergunta = estado.perguntas[estado.indice];
    Array.from($('opcoes').children).forEach((botao, indice) => {
      botao.disabled = true;
      if (indice === resposta.certa) botao.classList.add('certa');
      if (indice === escolha && !resposta.correta) botao.classList.add('errada');
    });
    $('feedback').textContent = (escolha < 0 ? '⏰ Tempo esgotado. ' : resposta.correta ? '✨ Certo! ' : '💫 Quase! ') + resposta.explicacao;
    $('barra-tempo').style.width = '0%';
    clearTimeout(proximoTempo);
    proximoTempo = setTimeout(() => {
      estado = Regras.avancar(estado);
      if (estado.terminou) finalizar();
      else desenharPergunta();
    }, 1400);
  }

  async function finalizar() {
    if (finalizando) return;
    finalizando = true;
    clearInterval(intervalo);
    clearTimeout(proximoTempo);
    const total = Regras.pontos(estado);
    $('resultado').textContent = total;
    $('acertos').textContent = estado.acertos;
    $('situacao-salvamento').textContent = 'Salvando seu resultado...';
    mostrar('tela-fim');
    try {
      await Placar.registrarPartida(total, { acertos: estado.acertos });
      $('situacao-salvamento').textContent = 'Resultado salvo neste aparelho.';
    } catch (erro) {
      $('situacao-salvamento').textContent = 'Não foi possível salvar: ' + erro.message;
    }
  }

  function comecar() {
    clearInterval(intervalo);
    clearTimeout(proximoTempo);
    finalizando = false;
    estado = Regras.novaPartida();
    mostrar('tela-jogo');
    desenharPergunta();
    intervalo = setInterval(atualizarRelogio, 100);
    $('opcoes').querySelector('button')?.focus();
  }

  document.addEventListener('keydown', (evento) => {
    if (!estado || bloqueado || $('tela-jogo').hidden || !/^[1-4]$/.test(evento.key)) return;
    evento.preventDefault();
    responder(Number(evento.key) - 1);
  });

  $('botao-jogar').addEventListener('click', comecar);
  $('botao-de-novo').addEventListener('click', comecar);
  mostrar('tela-inicio');
})();
