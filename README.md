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
```
# 2️⃣ Instalar dependências
```bash
flutter pub get
```

# 3️⃣ Configurar Firebase
# - Crie um projeto no Firebase Console
# - Ative Authentication (E-mail/Senha)
# - Crie a coleção "users" no Firestore
# - Baixe o google-services.json e coloque em android/app/

# 4️⃣ Rodar o app
```bash
flutter run
```

# 5️⃣ Gerar APK release
flutter build apk --release

# 6️⃣ Publicar nova versão
# - Vá em Releases no GitHub
# - Crie a tag v1.1.0
# - Envie o app-release.apk

# 7️⃣ Crie um projeto no Firebase Console:
# - https://console.firebase.google.com/

# 8️⃣ Ative:
🔸 Authentication (E-mail/Senha)
🔸 Cloud Firestore

# 9️⃣ Crie uma coleção chamada "users"

# 🔟 Baixe o arquivo google-services.json e coloque em:
# - android/app/google-services.json
# - Rodar o app 
```bash
flutter run
```
## 🔄 Publicar nova versão no GitHub

1️⃣ Gere o APK:
```bash
   flutter build apk --release
```
# 2️⃣ Vá até a aba "Releases" no seu repositório do GitHub

# 3️⃣ Crie uma nova release com a tag no formato:
   v1.1.0

# 4️⃣ Envie o arquivo:
   build/app/outputs/flutter-apk/app-release.apk

# 5️⃣ O app detectará automaticamente a nova versão e mostrará o alerta de atualização 🚀

## 🧩 Estrutura do Projeto
```bash
lib/
 ├── main.dart
 ├── models/
 │   └── crypto.dart
 ├── screens/
 │   ├── dashboard_screen.dart
 │   ├── crypto_detail_screen.dart
 │   └── perfil_screen.dart
 ├── services/
 │   └── app_update_checker.dart
 └── widgets/
     └── ...
```
## 💜 Desenvolvido com Flutter por Wesley Paredes
# 📧 E-mail: wesleyzbr@outlook.com
# 🌐 GitHub: https://github.com/wesleyparedes
## 🙏 Que Deus continue abençoando o Brasil









