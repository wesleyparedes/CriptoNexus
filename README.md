# 💰 CriptoNexus

> Um aplicativo Flutter moderno para acompanhar criptomoedas em tempo real, com gráficos, favoritos, notificações e atualização automática.

---

## 🚀 Funcionalidades

✅ **Dashboard em tempo real**  
Acompanhe o preço e variação das principais criptomoedas (via API do CoinGecko).  
Atualização automática a cada 30 segundos, com cache local inteligente.

✅ **Favoritos**  
Salve suas moedas preferidas e veja-as em destaque.

✅ **Conversor integrado**  
Converta valores entre Real (BRL) e qualquer criptomoeda disponível.

✅ **Notificações automáticas (FCM)**  
Receba alertas personalizados de movimentação de preços, mesmo com o app fechado.

✅ **Atualização automática do app**  
Verifica novas versões direto do GitHub e permite baixar o `.apk` com um clique.

✅ **Perfil do usuário (Firebase)**  
Gerencie nome, e-mail, foto e logout — sincronizado com Firestore e cache local.

---

## 🧠 Tecnologias Utilizadas

| Categoria | Tecnologias |
|------------|-------------|
| **Framework** | Flutter 3.x |
| **Linguagem** | Dart |
| **Backend** | Firebase Authentication, Firestore |
| **API Pública** | [CoinGecko](https://www.coingecko.com/) |
| **Notificações** | Firebase Cloud Messaging (FCM) |
| **Atualizações** | GitHub Releases API |
| **Armazenamento local** | SharedPreferences |
| **Download & Instalação** | Dio + OpenFilex |
| **Permissões & Imagens** | Permission Handler + Image Picker |

---

## 📱 Capturas de Tela (Exemplo)

| Dashboard | Calculadora | Perfil |
|:----------:|:------------:|:--------:|
| ![Dashboard](docs/screens/dashboard.png) | ![Calculadora](docs/screens/calculadora.png) | ![Perfil](docs/screens/perfil.png) |

> 💡 Coloque suas imagens em `docs/screens/` e altere os caminhos acima conforme necessário.

---

## ⚙️ Instalação e Execução

### 1️⃣ Clonar o repositório
```bash
git clone https://github.com/wesleyparedes/CriptoNexus.git
cd CriptoNexus
