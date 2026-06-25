FROM nginx:1.27-alpine

# Default nginx content ඉවත් කරන්න
RUN rm -rf /usr/share/nginx/html/*

# ඔබේ pre-built web files copy කරන්න
COPY build/web /usr/share/nginx/html

# Custom nginx config copy කරන්න
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

# Healthcheck (අවශ්‍ය නම්)
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]