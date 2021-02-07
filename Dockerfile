FROM node:12

COPY . .
RUN make

EXPOSE 8080
CMD [ "npm", "start" ]

