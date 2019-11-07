FROM python:3.6 as build_deps
WORKDIR /workspace
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM build_deps as build
COPY . .
RUN make html

FROM nginx:alpine
COPY --from=build /workspace/_build/html  /app/fe/
COPY devops/nginx/default.conf /etc/nginx/conf.d/default.conf

CMD nginx -g "daemon off;"
