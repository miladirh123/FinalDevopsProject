# Utiliser une image Node officielle
FROM node:18

# Créer un dossier de travail
WORKDIR /usr/src/app

# Copier package.json et installer les dépendances
COPY package*.json ./
RUN npm install

# Copier le reste du code
COPY . .

# Exposer le port
EXPOSE 3000

# Commande de démarrage
CMD ["npm", "start"]
