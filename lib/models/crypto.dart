// Em lib/models/crypto.dart

class Crypto {
  final String id;
  final String symbol;
  final String name;
  final String image;
  final double currentPrice;
  final double priceChangePercentage24h;
  final String curiosity; // <--- ADICIONE ESTA LINHA

  Crypto({
    required this.id,
    required this.symbol,
    required this.name,
    required this.image,
    required this.currentPrice,
    required this.priceChangePercentage24h,
    required this.curiosity, // <--- E ESTA AQUI
  });

  // Se você tiver um factory constructor fromJson, adicione a curiosidade nele também.
  factory Crypto.fromJson(Map<String, dynamic> json) {
    return Crypto(
      id: json['id'],
      symbol: json['symbol'],
      name: json['name'],
      image: json['image'],
      currentPrice: (json['current_price'] as num).toDouble(),
      priceChangePercentage24h: (json['price_change_percentage_24h'] as num).toDouble(),
      // Adicione uma curiosidade padrão ou puxe de algum lugar se a API tiver
      curiosity: getCuriosityForSymbol(json['symbol']),
    );
  }
}

// Função auxiliar para obter curiosidades (exemplo)
String getCuriosityForSymbol(String symbol) {
  switch (symbol.toLowerCase()) {
    case 'btc':
      return 'O criador do Bitcoin, Satoshi Nakamoto, é um pseudônimo. Até hoje, sua verdadeira identidade é um mistério.';
    case 'eth':
      return 'O Ethereum foi proposto em 2013 por Vitalik Buterin, que na época tinha apenas 19 anos de idade.';
    case 'sol':
      return 'Solana é conhecida por sua alta velocidade, sendo capaz de processar dezenas de milhares de transações por segundo.';
    case 'xrp':
      return 'O XRP foi projetado para ser uma ponte entre moedas tradicionais, permitindo pagamentos internacionais quase instantâneos e com custo muito baixo para instituições financeiras.';
    case 'ada':
      return 'Cardano foi fundada por Charles Hoskinson, um dos co-fundadores do Ethereum, e se orgulha de sua abordagem baseada em pesquisas acadêmicas revisadas por pares.';
    case 'doge':
      return 'Dogecoin começou como uma piada em 2013, baseada no popular meme "Doge" de um cachorro Shiba Inu. Hoje, é famosa por sua comunidade vibrante e gorjetas online.';
    case 'ltc':
      return 'Frequentemente chamado de "a prata para o ouro do Bitcoin", o Litecoin foi um dos primeiros "altcoins" e processa blocos quatro vezes mais rápido que o Bitcoin.';
    case 'usdt':
      return 'O Tether (USDT) é uma "stablecoin", o que significa que seu valor é lastreado em uma moeda fiduciária, como o dólar americano, para manter seu preço estável em torno de 1 dólar.';
    case 'bnb':
      return 'BNB é a criptomoeda nativa da corretora Binance. Originalmente, era usada para pagar taxas com desconto, mas hoje alimenta um vasto ecossistema, incluindo sua própria blockchain.';
    case 'dot':
      return 'O principal objetivo do Polkadot é a "interoperabilidade", permitindo que diferentes blockchains se comuniquem e transfiram dados e valor entre si de forma segura.';
    case 'xmr':
        return 'Monero é a criptomoeda mais famosa focada em privacidade. Suas transações são anônimas e irrastreáveis, ocultando o remetente, o destinatário e a quantia enviada.';
    default:
      return 'Criptomoedas usam criptografia para garantir transações seguras e controlar a criação de novas unidades.';
  }
}