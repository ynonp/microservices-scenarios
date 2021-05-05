FROM node:14
WORKDIR /myapp
COPY package*.json ./
RUN npm install
RUN npm install -g nodemon

# Add a script to be executed every time the container starts.
COPY entrypoint.sh wait-for-it.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh /usr/bin/wait-for-it.sh
ENTRYPOINT ["entrypoint.sh"]

# Configure the main process to run when running the image
CMD ["node", "main.js"]
