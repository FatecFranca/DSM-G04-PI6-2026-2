import "dotenv/config";
import { prisma } from "../lib/prisma";

const rawData = `
BARRACAO SKATE CLUB	bar	media	informal	jovem	4,8	22:00	03:00
Matheus & Rosaria Bar	bar	media	formal	jovem	4,6	11:00	00:00
Bar da Careta	bar	media	formal	jovem	4,4	16:00	01:00
Villa Madalena Soul Bar	bar	caro	formal	adulto	4,6	11:00	00:00
Espina Espetos	bar	barato	informal	jovem	4,4	10:30	23:00
Jacare	bar	medio	informal	jovem	4,7	11:00	14:30
The roots	bar	medio	informal	jovem	4,6	20:00	02:00
Bitelo	hamburgueria	medio	informal	jovem	4,5	18:00	01:00
Chic10	lanchonete	barato	formal	jovem/adulto	4,5	10:00	03:00
Brutu's Lanches	lanchonete	barato	formal	jovem/adulto	4,4	10:00	03:00
Bonitos	lanchonete	barato	informal	jovem/adulto	4,5	16:30	01:00
Capitao Prime	hamburgueria	barato	formal	jovem/adulto	4,8	18:00	23:30
Senhor Burguer	hamburgueria	barato	formal	jovem/adulto	4,5	19:00	23:30
Games Burguer	restaurante	medio	informal	jovem/adulto	4,8	16:00	02:00
Peks	restaurante	barato	informal	jovem	4,9	19:00	23:00
Miguelzinho Snooker Bar	bar	barato	informal	jovem	4,3	16:00	03:00
Bistro	restaurante	medio	formal	adulto	4,7	11:00	14:00
Cafeteria Affamato	cafeteria	caro	formal	adulto	5	09:00	17:30
Rancho Picanha na Tabua	restaurante	medio	formal	adulto	4,5	18:00	22:30
Choperia n1	bar	medio	informal	jovem	4,8	11:00	23:00
bar do gerente	bar	medio	informal	jovem	4,6	17:00	01:00
maria e jose parrilha	restaurante	caro	formal	jovem/adulto	4,4	11:00	23:00
The Spot	restaurante	barato	informal	jovem	4,6	08:00	00:00
Pesque & Pague Santa Clara	restaurante	medio	formal	adulto	4,4	10:00	18:00
tabua mista	restaurante	barato	formal	adulto	4,1	11:00	00:00
taberna	bar	caro	formal	jovem	4,5	17:00	23:00
gran rock	bar	caro	informal	jovem	4,9	18:30	00:00
Brooks Hamburgueria	hamburgueria	medio	formal	jovem/adulto	4,6	18:00	00:00
burguer house	hamburgueria	barato	formal	adulto	4,6	18:30	23:30
Boteco do Joca	bar	barato	formal	jovem/adulto	4,4	11:00	23:00
agro bar	bar	medio	formal	jovem	3,7	17:00	20:00
O Boteco do Patio	bar	barato	formal	jovem	4,8	17:00	23:00
TutiYa Sushi Bar - Comida Japonesa	restaurante	caro	formal	adulto	4,7	11:00	23:00
daniel san	restaurante	caro	formal	adulto	4,4	18:00	23:00
Atlantico Gastrobar	bar	caro	formal	adulto	4,4	11:30	00:00
Sao Bernardo Bar e Cervejaria	bar	medio	formal	jovem	4,8	18:00	00:00
Planeta Malte Bar	bar	medio	formal	adulto	4,8	17:00	00:00
feitoria da cerveja	bar	medio	formal	adulto	4,8	16:00	23:00
confraria	bar/hamburgueria	barato	formal	jovem/adulto	4	16:00	23:30
duze	hamburgueria	barato	formal	adulto	4,6	17:00	00:00
Cascata Pizzas Rodizio	pizzaria	barato	formal	adulto	4,1	19:00	23:30
pizza bar	pizzaria	medio	formal	adulto	4,5	18:15	23:30
Parmegiana Pizzas	pizzaria	medio	formal	adulto	4,3	10:00	23:30
Mousse Cake Franca - Cafe e Restaurante	restaurante	caro	formal	adulto	4,3	09:00	22:40
Pizzaria Castelo Franca	pizzaria	barato	formal	adulto	4,6	18:00	00:00
costelao de ouro	restaurante	caro	informal	jovem/adulto	4,5	18:00	23:00
Scamboo Petiscaria	lanchonete	caro	formal	jovem/adulto	4,4	17:00	01:30
Konomi	restaurante	caro	formal	adulto	4,7	11:00	22:00
box beef	restaurante	medio	informal	jovem	4,4	10:00	23:00
pereira	bar	barato	informal	jovem	4,7	17:00	23:00
Morada du Capiau	bar	caro	formal	adulto	4,7	19:00	02:00
laber jake	restaurante	barato	formal	jovem/adulto	4,6	20:00	23:00
Culinaria tex-mex	restaurante	caro	formal	jovem/adulto	4,8	19:00	00:00
lambari	lanchonete	caro	formal	adulto	4,7	18:30	23:30
Traira Resto - Bar E Choperia	bar	barato	formal	jovem	2,5	19:00	00:00
Madero & Jeronimo Burger Franca	hamburgueria	caro	formal	adulto	4,6	11:30	23:00
Barbarus Burger - Hamburgueria Medieval	hamburgueria	medio	formal	jovem/adulto	4,7	18:00	23:30
Hamburgueria Alameda	hamburgueria	caro	formal	jovem/adulto	4,7	19:00	23:00
TRAPSTAR BURGUER	hamburgueria	caro	formal	jovem/adulto	4,9	18:00	23:00
bahia lanches	lanchonete	barato	informal	jovem/adulto	4,5	17:00	01:00
Nostravamus o bar	bar	barato	informal	jovem	4,6	16:00	00:00
Noite Nossa Bar	bar	medio	informal	jovem	4,6	17:30	01:00
Quintal Bar do Burrinho	bar	medio	informal	jovem	4,6	17:30	01:30
Villa Franca Bar	bar	caro	informal	jovem	4,7	16:00	00:00
Shadow Wolf - Beer Spot	bar	caro	formal	jovem	4,9	10:00	23:00
Armazem 43	bar	barato	informal	jovem	4,5	17:00	01:00
Brothers Bar e Petiscaria	bar	caro	informal	jovem/adulto	4,6	17:00	00:00
Chopperia Raposa do Artico	bar	caro	informal	adulto	4,4	11:00	00:00
Bar'Budus Beer e Chopp	bar	medio	informal	jovem	4,7	17:00	00:00
BarUke beer	bar	medio	informal	jovem	4,8	17:00	00:00
Butecando Franca Espeto Bar	bar	barato	informal	jovem	4,8	18:00	23:00
Barucksbar	bar	medio	informal	jovem	4,7	15:00	23:00
Butiquim do Sabia	bar	barato	informal	jovem	4,4	17:00	00:00
Petiscaria Mineira/Bar do twonay	bar	medio	informal	adulto	4,4	16:45	01:00
Garrafada Coqueteis | Bar em Franca	bar	medio	informal	jovem	5	17:30	01:00
Embrazza - Espeto Bar	bar	medio	informal	jovem/adulto	5	17:00	01:00
Espetisko's Bar	bar	barato	informal	jovem/adulto	4,7	18:00	00:00
Padrao 12 Bar	bar	medio	informal	jovem	4,3	16:30	02:00
After Burguer - Hamburgueria	hamburgueria	caro	informal	jovem/adulto	4,6	18:00	04:30
Escritorio Bar	bar	barato	informal	jovem	4,7	15:30	00:00
Biroska do Piri	bar	medio	informal	jovem/adulto	4,9	16:00	00:00
Bar do Zam	bar	barato	informal	jovem	4,7	15:30	23:30
Capetaria Tony	bar	medio	informal	jovem	4,7	18:00	03:00
FRIO DA MADRUGADA	bar	caro	formal	jovem/adulto	4,2	10:30	00:00
OquiOsque Pastelburger	hamburgueria	caro	formal	jovem/adulto	5	10:00	23:00
Fratelli Burguer	hamburgueria	medio	formal	jovem/adulto	4,3	18:30	23:00
Darini's Burguer	hamburgueria	medio	formal	jovem/adulto	4,8	18:30	00:00
barba	restaurante	medio	formal	jovem	4,5	19:00	02:00
Larica na Brasa	hamburgueria	medio	formal	jovem/adulto	4,2	18:00	00:00
Muvuca Lanches e Hot Dogs	lanchonete	barato	informal	jovem/adulto	4,5	11:00	05:00
Altas Horas Lanches	restaurante	barato	informal	jovem/adulto	4,6	19:00	03:00
Cia Japa Franca	restaurante	caro	formal	adulto	4,6	18:00	23:00
Saiko Nani	restaurante	caro	informal	adulto	4,8	12:00	00:00
HAMMAY SUSHI	restaurante	caro	formal	adulto	5	11:00	22:30
Lu Wasabi	restaurante	medio	informal	adulto	4,6	18:30	00:00
Yuyake Sushi	restaurante	medio	formal	adulto	4,6	19:00	23:00
Cobra Kai	restaurante	caro	formal	adulto	4,3	11:00	00:00
Sumo Day	restaurante	caro	formal	adulto	4,5	11:30	23:30
Keyko Sushi Bar	bar	caro	formal	jovem/adulto	4,5	18:00	23:00
Jin Jin wok	restaurante	medio	formal	adulto	4,2	10:00	21:30
Pizzaria Tarantella Franca - Pizzas Artesanais	pizzaria	medio	formal	adulto	4,6	18:00	01:00
Pizzaria Boa Massa	pizzaria	medio	formal	adulto	4,7	18:00	23:30
Pizzaria D'Napole	pizzaria	medio	formal	adulto	4,5	18:00	00:00
Two Brother's Pizzaria	pizzaria	caro	formal	adulto	4,9	19:00	23:30
Bau da Pizza	pizzaria	medio	formal	adulto	4,1	18:00	00:00
Bella Capri Pizzaria - Franca	pizzaria	barato	formal	adulto	4,6	18:00	23:00
Pizzaria Vitoria Franca	pizzaria	barato	formal	adulto	4,7	16:00	23:00
Mozzarella Pizzaria	pizzaria	barato	formal	adulto	4,4	18:00	23:30
City Lanches	pizzaria	barato	formal	jovem/adulto	4,2	18:00	02:00
Sapataria da Pizza	pizzaria	caro	formal	adulto	4,7	18:00	23:30
Pizzaria Aquarius	pizzaria	medio	formal	adulto	4,7	18:30	23:00
Bella Gula Pizzaria	pizzaria	medio	formal	adulto	4,9	18:30	23:00
Pizzaria do Gaucho	pizzaria	medio	formal	adulto	4,5	17:00	23:30
Bar do Alemao	bar	medio	informal	adulto	4,4	17:00	00:00
Picanha do Ze	restaurante	medio	familiar	adulto	4,6	11:00	15:00
Santa Pizza	pizzaria	medio	familiar	adulto	4,5	18:00	23:30
Beco Burguer	hamburgueria	medio	informal	jovem/adulto	4,7	18:00	23:00
Bar do Paulista	bar	barato	informal	adulto	4,3	16:00	23:00
Cantina da Nonna	restaurante	medio	familiar	adulto	4,6	11:30	14:30
Tokyo Sushi Franca	restaurante	caro	formal	adulto	4,5	18:30	23:30
Chopp Time Franca	bar	medio	informal	adulto	4,4	17:00	00:00
Espeto do Chef	bar	barato	informal	adulto	4,2	18:00	23:00
Pizzaria La Casa	pizzaria	medio	familiar	familiar	4,6	18:00	23:00
Garage Beer	bar	medio	informal	adulto	4,7	18:00	01:00
Pastelaria Central	lanchonete	barato	familiar	todos	4,4	09:00	20:00
Villa Grill	restaurante	medio	familiar	adulto	4,5	11:00	22:00
Burger 360	hamburgueria	medio	informal	jovem	4,6	18:00	23:30
Cafe do Centro	cafeteria	barato	formal	adulto	4,5	08:00	18:00
Bar do Chicao	bar	barato	informal	adulto	4,3	16:00	22:00
Espaco Prime Franca	restaurante	caro	formal	adulto	4,7	19:00	23:00
Ponto do Hot Dog	lanchonete	barato	informal	jovem	4,4	18:00	23:00
Bar e Petiscaria Sao Jorge	bar	medio	informal	adulto	4,5	17:00	00:00
Sabor Mineiro Franca	restaurante	medio	familiar	adulto	4,6	11:00	15:00
`;

type SeedEstabelecimento = {
  nome: string;
  tipo: string;
  faixa_preco: string;
  ambiente: string;
  publico: string;
  avaliacao: number;
  abre: string;
  fecha: string;
};

function normalize(value: string) {
  return value.trim().toLowerCase();
}

function parseRows(): SeedEstabelecimento[] {
  const rows = rawData
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean);

  const uniqueByName = new Map<string, SeedEstabelecimento>();

  for (const row of rows) {
    const parts = row.split("\t").map((item) => item.trim());
    if (parts.length < 8) continue;

    const nome = parts[0];
    const faixaPrecoRaw = normalize(parts[2]);
    const ambienteRaw = normalize(parts[3]);
    const publicoRaw = normalize(parts[4]);
    const avaliacaoRaw = parts[5].replace(",", ".");

    const estabelecimento: SeedEstabelecimento = {
      nome,
      tipo: normalize(parts[1]),
      faixa_preco: faixaPrecoRaw === "média" ? "medio" : faixaPrecoRaw,
      ambiente: ambienteRaw === "fomral" ? "formal" : ambienteRaw,
      publico: publicoRaw
        .replace("aduldo", "adulto")
        .replace("jovem adulto", "jovem/adulto"),
      avaliacao: Number.parseFloat(avaliacaoRaw),
      abre: parts[6],
      fecha: parts[7],
    };

    uniqueByName.set(normalize(nome), estabelecimento);
  }

  return [...uniqueByName.values()];
}

async function main() {
  await prisma.tb_modelo_recomendacao.upsert({
    where: { versao: "fallback-v1" },
    create: {
      versao: "fallback-v1",
      algoritmo: "rule-based-fallback",
      status: "ready",
      trained_at: new Date(),
    },
    update: {
      algoritmo: "rule-based-fallback",
      status: "ready",
    },
  });

  const total = await prisma.tb_estabelecimento.count();
  if (total > 0) {
    console.log(`Estabelecimentos ja existentes: ${total}. Seed de modelo fallback garantido.`);
    return;
  }

  const data = parseRows();
  if (data.length === 0) {
    throw new Error("Nenhum estabelecimento valido encontrado para seed.");
  }

  await prisma.tb_estabelecimento.createMany({ data });
  console.log(`Seed concluido: ${data.length} estabelecimentos inseridos e modelo fallback-v1 garantido.`);
}

main()
  .catch((error) => {
    console.error("Erro no seed:", error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
