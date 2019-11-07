# template start(模版内容标志行，不可删除)
# python项目的基本Dockerfile模版，主要包含test，lint，build相关检查，项目需要根据自身情况修改该模版
FROM python:3.6 as build_deps
EXPOSE 80
WORKDIR /workspace
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        vim supervisor gettext
ADD requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

FROM build_deps as run_lint
ADD requirements-dev.txt ./
RUN pip install --no-cache-dir -r requirements-dev.txt
ADD . .
ARG base_commit_id=""
RUN pre-commit install \
    && make BASE_COMMIT_ID=${base_commit_id} lint

FROM build_deps as run_test
ADD . .
RUN make test

FROM build_deps as build

RUN pip install uwsgi
ADD . .
COPY uwsgi.ini /etc/uwsgi/uwsgi.ini
CMD python manage.py migrate && supervisord

# custom start(自定义内容标志行与下面空行，不可删除)
