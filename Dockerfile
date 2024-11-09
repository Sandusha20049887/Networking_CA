FROM node:10-slim

WORKDIR /usr/src/app

COPY index.js .

# If you are building your code for production
# RUN npm ci --omit=dev

# COPY . .

EXPOSE 3000

CMD [ "node", "index.js" ]