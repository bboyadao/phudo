FROM nginx:latest
COPY ./conf.d/local.conf /etc/nginx/conf.d/local.conf
EXPOSE 80 443
ENTRYPOINT ["nginx", "-g", "daemon off;"]
