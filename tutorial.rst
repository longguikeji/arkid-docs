部署与配置
==========

.. MUTABLE ON REFACTOR

一账通的主体是一个提供 HTTP RESTful API 的 Django 项目，并含有一些存储组件，一个基于 MySQL 的 LDAP 协议适配器，一个 Nginx 反向代理以及一个可选的图形前端。一账通提供了一个 ``settings_local.py`` 文件对整个项目进行统一配置。由于项目结构相对复杂，部署与配置较为繁琐，推荐使用 Helm_ 在 Kubernetes_ 上进行部署以避免手工配置协调项目组件。


================ ==============
 部署方式          建议
---------------- --------------
Kubernetes 部署    推荐
Docker 部署        可选
手工部署            不推荐
================ ==============

Kubernetes 部署
---------------

.. seealso::
   * `Kubernetes 官方文档`_
   * `Helm 用户指南`_

环境需求
::::::::

:必需:
   * 一个正确部署了 Tiller 的 Kubernetes 集群
   * 一个可访问该集群的 Helm 客户端

:推荐:
   * 一个 `Ingress 控制器`_
   * 一个可以被解析到服务器上的独立域名
   * Kubernetes 集群中部署了 cert-manager_ 组件

如何部署
::::::::

1. 获取一账通的 Helm Chart。

    .. code-block:: shell

       git clone https://github.com/longguikeji/arkid-charts.git

       cd arkid-charts/chart

2. 使用 ``values.yaml`` 进行项目配置。

    .. code-block:: shell

       vim values.yaml

    .. seealso::
       * `如何配置`_
       * `settings_local.py 详解`_

3. 使用 Helm 将一账通部署到 Kubernetes 集群中。

    .. code-block:: shell

       helm install arkid .

4. 等待服务启动完成之后，测试应用是否正确运行 [#f1]_。

    .. code-block:: shell

       export ARKID_PORTAL_POD=$(kubectl get pods \
       -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' \
       --selector=app.kubernetes.io/name=arkid-portal)

       kubectl port-forward $ARKID_PORTAL_POD 10080:80

       http -F GET http://127.0.0.1:10080/ping
    ..

如何配置
::::::::

在此种部署方式下，所有的配置均可通过 ``values.yaml`` 完成，而 ``settings_local.py`` 则作为 Kubernetes 的 ConfigMap 组件存在。因此在本小节中，除非显式说明，所有的文字均关联于对 ``values.yaml`` 的检视或修改。

.. ASYNC CROSS REFERENCE TODO:
   ArkOS

:必须:
   * *必须* 配置 ``settingsLocal`` ConfigMap 项到合适的状态，详见 `settings_local.py 详解`_。
   * 如未使用 ArkOS，``apiServer`` *必须* 置空。
   * 如为初次使用，``presistence.init`` *必须* 设置为 ``true``。
   * 如果配置了 Ingress 控制器，``ingress.annotations.kubernetes.io/ingress.class`` *必须* 设置为控制器的类型。
   * 如果 Ingress 控制器所在的服务器拥有域名并且域名解析正常，``ingress.host.name`` *必须* 设置为该域名。

:推荐:
   * *推荐* 在目标集群中部署 cert-manager 并开启 ``ingress.cert`` 及 ``ingress.tls``。
   * *推荐* 修改 ``presistence.mysql.rootPassword`` 及 ``ldap.adminPassword`` 为合适的口令。

.. ASYNC TODO:
   Disable FE

:可选:

.. TODO:
   Separate OPTIONAL, SHOULD NOT & MUST NOT

部署流程解析
::::::::::::

.. TODO:
   Deployment Process

Docker 部署
-----------

.. ASYNC TODO:
   Docker Compose

手工部署
--------

本地调试
--------

``settings_local.py`` 详解
--------------------------

.. TODO
   Docker Compsoe
   Manual

``settings_local.py`` 本质上是对 Django 框架默认配置文件 ``settings.py`` 的覆写，但一账通不推荐用户修改除开发人员暴露出来的部分之外的任何配置。该文件的配置样例详见 `settings_example.py`_，本节会指出其中必须更改的部分并选择性说明其中部分选项，并在最后给出 ``settings_example.py`` 的全文。

:必须:
   * 在生产环境下，*必须* 重新生成一个 ``SECRET_KEY`` 并将 ``DEBUG`` 置为  ``False``。

:推荐:
   * *推荐* 将 ``PRIVATE_IP``、``PUBLIC_IP`` 及 ``BASE_URL`` 依自身网络配置正确填写。如果使用 Ingress，应填写为 Ingress 控制器的 IP 地址或域名，并根据是否使用 TLS 选择协议。它们是 UI 中的展示性信息，被用于向第三方应用提供接入信息（如 OAuth2.0 端点 URI）。
   * 理由同上，*推荐* 正确配置 ``LDAP_SERVER`` 及 ``LDAPS_SERVER``。

:可选:
   * 如需启用自定义头像或公司登录页等需求文件存储的服务，*可以* 自行配置或购买 MinIO 服务并填写 ``MINIO_*`` 配置。
   * 如需启用向第三方应用同步的功能，需向 ``EXECUTERS`` 中追加相应的组件，目前只支持钉钉。

:不推荐:
   * 在基于 Chart 的环境下， *不推荐* 手动修改 ``DATABASES``、``REDIS_CONFIG`` 相关配置及 ``LDAP_*`` （除用于展示的URI），而应通过 ``values.yaml`` 进行配置。

.. code-block:: python

   # pylint: disable=undefined-variable, wrong-import-position, line-too-long
   '''
   settings.py 自定义配置示例
   此示例涉及外的配置，除非明确知晓后果，否则不建议修改
   建议在项目根路径下创建 settings_local.py，并只声明修改的部分。ArkID 将会加载此配置并追加覆盖到 settings.py
   '''

   # SECURITY

   # - 正式环境中请重新生成 SECRET_KEY
   ## > In [1]: from django.core.management.utils import get_random_secret_key
   ## > In [2]: get_random_secret_key()
   ## > Out[2]: '$_&vn(0rlk+j7+cpq$$d=2(c1r(_8(c13ey51nslmm_nr6ov(t'
   SECRET_KEY = "$_&vn(0rlk+j7+cpq$$d=2(c1r(_8(c13ey51nslmm_nr6ov(t"

   # - 并关闭 debug 模式
   DEBUG = False

   # DATABASES

   # - 默认使用 sqlite3
   DATABASES = {
       'default': {
           'ENGINE': 'django.db.backends.sqlite3',
           'NAME': os.path.join(BASE_DIR, 'db', 'db.sqlite3'),
       }
   }

   # - 正式环境推荐使用 MySQL
   ## client 为 pymysql，已在 requirements 中声明
   ## 若使用其他 client，需自行安装依赖
   import pymysql
   pymysql.install_as_MySQLdb()
   DATABASES = {
       'default': {
           'ENGINE': 'django.db.backends.mysql',
           'NAME': 'database_name',
           'USER': 'root',
           'PASSWORD': 'password',
           'HOST': 'localhost',
           'PORT': '3306',
           'OPTIONS': {
               'autocommit': True,
               'init_command': 'SET default_storage_engine=MyISAM',
           },
       }
   }

   # DOMAIN && IP
   # - 内网IP
   PRIVATE_IP = '192.168.0.150'
   # - 公网IP
   PUBLIC_IP = '47.111.105.142'
   # - 访问地址
   ## 如果不能被公网访问将会影响部分需与第三方交互的功能，比如钉钉扫码登录等
   BASE_URL = 'https://arkid.longguikeji.com'
   BASE_URL = "http://47.111.105.142"

   # storage
   # - 目前文件一律存储于 minio 中，minio 的搭建不在此讨论范畴
   MINIO_ENDPOINT = 'minio.longguikeji.com'
   MINIO_ACCESS_KEY = '****'
   MINIO_SECRET_KEY = '****'
   MINIO_SECURE = True
   MINIO_LOCATION = 'us-east-1'
   MINIO_BUCKET = 'arkid'

   # - 本地文件
   ## TODO：接下来将会支持基于本地文件系统的文件存储

   # Redis
   REDIS_CONFIG = {
       'HOST': '192.168.0.147',
       'PORT': 6379,
       'DB': 7,
       'PASSWORD': 'password',
   }
   ## REDIS_URL, CACHES, CELERY_BROKER_URL 均依赖于 REDIS_CONFIG
   ## 如果在 settings_local 文件中修改了 REDIS_CONFIG，上述变量需重新声明，使 REDIS_CONFIG 的改动生效。
   REDIS_URL = 'redis://{}:{}/{}'.format(REDIS_CONFIG['HOST'], REDIS_CONFIG['PORT'], REDIS_CONFIG['DB']) if REDIS_CONFIG['PASSWORD'] is None \
           else 'redis://:{}@{}:{}/{}'.format(REDIS_CONFIG['PASSWORD'], REDIS_CONFIG['HOST'], REDIS_CONFIG['PORT'], REDIS_CONFIG['DB'])
   CACHES["default"]["LOCATION"] = REDIS_URL
   CELERY_BROKER_URL = REDIS_URL

   # LDAP

   # - 启用 sql_backend ldap
   ## 需安装 ArkID  > docker pull longguikeji/ark-sql-ldap:1.0.0
   ## 且 database 为 MySQL
   ## 此时所有针对 LDAP_* 的配置均不对 LDAP server 生效。只读。
   ## TODO：支持LDAP_BASE、LDAP_PASSWORD 可修改。
   INSTALLED_APPS += ['ldap.sql_backend']

   ## LDAP server 的访问地址，用于展示
   LDAP_SERVER = 'ldap://localhost'
   LDAPS_SERVER = 'ldaps://localhost'

   # - 启用 native ldap (不建议使用)
   ## 需已有 LDAP server 且 LDAP 内没有数据
   ## 各对接信息按 此 LDAP server 实际情况填写
   EXECUTERS += ['executer.LDAP.LDAPExecuter']

   LDAP_SERVER = 'ldap://192.168.3.9'
   LDAPS_SERVER = 'ldaps://192.168.3.9'
   LDAP_BASE = 'dc=longguikeji,dc=com'
   LDAP_USER = 'cn=admin,dc=longguikeji,dc=com'
   LDAP_PASSWORD = 'admin'
   ## 此三项由arkid生成，只读。应依赖于LDAP_BASE,故需重新声明
   LDAP_USER_BASE = 'ou=people,{}'.format(LDAP_BASE)
   LDAP_DEPT_BASE = 'ou=dept,{}'.format(LDAP_BASE)
   LDAP_GROUP_BASE = 'cn=intra,ou=group,{}'.format(LDAP_BASE)

   # 钉钉
   # - 向钉钉同步数据
   EXECUTERS += ['executer.Ding.DingExecuter']

.. rubric:: 注

.. [#f1] 本文档使用 HTTPie_ 而不是 cURL 作为示例 HTTP 客户端，前者拥有更加直观的命令行选项，较之后者更易于使用。

.. _HTTPie: https://httpie.org
.. _docker: https://www.docker.com
.. _kubernetes: https://kubernetes.io
.. _helm: https://helm.sh
.. _cert-manager: https://github.com/jetstack/cert-manager

.. _Kubernetes 官方文档: https://kubernetes.io/zh/docs/
.. _Helm 用户指南: https://whmzsu.github.io/helm-doc-zh-cn/


.. _Ingress 控制器: https://kubernetes.io/zh/docs/concepts/services-networking/ingress-controllers/

.. _settings_example.py: https://github.com/longguikeji/arkid-core/blob/yh/settings/oneid/settings_example.py

用户界面
========

以下几乎所有内容均基于「已经存在一个拥有图形界面的一账通实例，并且用户在该实例拥有管理员权限」这一假设，不妨设这一实例的地址为 ``https://arkid-example.com``，管理员的用户名与密码分别为 ``admin`` 与 ``password``。

使用 Web 图形界面
-----------------

如果一个一账通实例在部署时决定配置 Web 前端，那么用户在此时即可拥有一个设计友好易于使用的界面。本小节的余下部分将指引用户（无论是普通用户还是管理员）使用这一图形界面探索一账通的核心功能。

注册与登录
::::::::::

无论如何，只要一个一账通实例决定对外公开自身的存在，用户就总可以通过浏览器访问到该实例的登录界面。如果该实例选择开放注册，那么任何人都可以在此处使用邮箱或手机注册一个账号并登录。如若不然，用户只能选择要求这个实例的管理员为自己手动添加一个账号，并通过管理员提供的链接绑定并激活账号。


.. figure:: assets/登录.*
   :align: center

   登录界面

工作台
::::::

每个一账通用户都拥有一个「工作台」，它允许用户检视本账号被授权访问的应用，系统内其他可见组织与成员的基本信息，以及配置自身的个人信息。

我的应用
........

「我的应用」页面展示了所有当前用户有权访问（即可用自己的一账通账号进行授权登录操作的）的应用的基本信息。若管理员为某应用配置了跳转链接，用户可以直接点击该应用以跳转到应用地址。

.. figure:: assets/我的应用.*
   :align: center

   我的应用

通讯录
......

用户可以在「通讯录」中检索所有自身可见的组织结构与用户的基本信息，检索的目标对象的可见性取决于当前用户的权限。

.. figure:: assets/通讯录.*
   :align: center

   通讯录

其他
....

每个用户都可以检视自身的「个人资料」页面并在此处更改自身的基本信息，这些信息可在「通讯录」中被其他用户检索（取决于对方的权限）。用户也可在右上角的下拉菜单里选择修改当前账号的密码或是登出一账通。

.. figure:: assets/个人资料.*
   :align: center

   个人资料

.. attention::
   在一账通中，一旦用户选择登出，不仅仅是对一账通自身的访问凭据会被撤销，所有处于登录状态的第三方应用的访问凭据也会被一并撤销。这是对所谓「单点登出（Single Sign-Out）」机制的一种实现。


管理后台
::::::::

如果当前用户拥有管理员权限，那么该用户可以通过右上角的「管理后台」按钮来配置当前一账通实例的行为。

账号管理
........

管理员可在「账号管理」–「所有账号」页面内添加新账号，检视、编辑已有账号或调整它们的权限，并可以将账号信息批量导出为 ``.csv`` 文件或从具有特定格式的 ``.csv`` 文件中批量导入。

.. figure:: assets/所有账号.*
   :align: center

   账号管理–所有账号

.. important:: 对于手动添加的账号，管理员需要将邀请链接（在尚未激活的账号的「操作」一栏中获取）发送给相应的用户，让其完善注册信息并激活账号。

.. TODO:
   csv格式的具体定义，以及其与网页UI可编辑字段的不一致性

账号注册
........

「账号管理」–「账号配置」页面内提供了一些登录注册必不可少的基础设施。如是否开放注册，是否开放第三方扫码登录以及如何配置注册所需的邮箱/手机验证码服务。

.. figure:: assets/账号配置.*
   :align: center

   账号管理–账号配置

.. note::
   虽然验证码校验在账号激活的过程中必不可少，但一账通本身并不提供验证码服务。用户需要自行准备邮箱或短信服务并在一账通内部配置好相应的接口。

账号同步
........

在「账号管理」——「账号同步」页面中可以启用在一账通系统与其他平台的用户对象模型之间同步对接的功能。在填写了同步目标平台的认证信息之后，点击「开始同步」按钮即可将目标平台的所有用户及分组等对象同步到当前一账通实例中。

.. figure:: assets/账号同步.*
   :align: center

   账号管理–账号同步

.. attention::
   当同步完成之后，在一账通平台上的任何修改都会同步应用到目标平台之上，但目标平台上的修改并不会反向同步给一账通，因此不推荐在同步完成之后修改目标平台的用户数据。

.. TODO:
   用户模型映射算法？

应用配置
........

管理员可在「应用管理」页面下检索、删除、接入第三方应用以及管理它们的权限，接入第三方应用的详细说明见 `第三方应用接入`_ 部分。如果用户有通过一账通登录某应用的权限，那么该应用会出现在用户的工作台上。

.. figure:: assets/应用管理.*
   :align: center

   应用管理

.. tip::
   如果为一个应用配置了跳转链接，用户就可以直接在工作台中直接点击访问该应用了。

分组管理
........

一账通系统中存在着应用、用户与分组这三类主要的业务对象。分组功能将用户以分组对象关联起来，而权限系统则涉及应用与后两者之间的交互。

.. glossary::
   分组
      一账通中的分组结构是一棵有根的 `树`_，其中每个节点可以拥有有限多个子节点（子组）以及有限多个值（用户），与常见的目录树结构基本一致。

   分组类型
      一账通中允许存在多种不同的分组方式，每一种由一个分组类型来定义。可以为一个分组类型创建多个实例，每个实例都构成了一个分组结构。一账通默认提供「部门」、「角色」以及「标签」三种分组类型，并允许用户无限制的自定义分组类型，不同的分组类型之间完全正交。

   用户
      用户是分组结构中的「值」，不包含任何结构，而仅仅是属于某个特定结构。但与文件系统不同，一个用户可以同时属于多个分组（无视分组类型）。

.. note::
   可以将一个分组类型的实例视为一棵树，而一个分组类型则构成了一个 `森林`_，或是直接将分组类型视为一棵树的根，而所有的实例则不过是分组类型的「子组」而已。

管理员可以在「分组管理」页面下检视管理所有已有的分组结构并定义新的分组或类型，也可以查看特定的分组节点中包含的所有用户。

.. figure:: assets/分组管理.*
   :align: center

   分组管理

.. hint::
   「分组管理」页面下的成员管理功能暂时只支持调整分组中已有成员的位置或手动添加全新账号（功能与「所有账号」页面下的一致），如需添加已有用户到特定分组中来，暂时只能通过「编辑账号」操作进行。

权限管理
........

一账通为管理者提供了一套完备而可扩展的精细权限控制系统，允许通过各种策略为每一个用户配置应用的访问权限，管理应用与分组的可见性，以及配置权限受限的子管理员辅助管理。

.. note::
   在一账通的权限系统中，分组是权限管理的一个基本单位。权限可以被直接指派给分组，任何指派给分组的权限会被指派给该分组的直接用户，或是（通过某些选项）递归的指派给该分组的子组与其中的用户。在分组结构中，指派给前驱节点（上级分组）的权限总可以被指派给其后继节点（子组）的权限所覆盖。

可见性权限
''''''''''

分组结构以及其中成员的详细信息（如个人资料）的可见性权限配置应在「分组管理」页面的分组实例编辑中进行，有如下几种权限策略：

+---------------------------------+
|分组可见性权限                   |
+=================================+
|所有人可见                       |
+---------------------------------+
|仅组内成员可见（下属分组不可见） |
+---------------------------------+
|组内成员及其下属分组可见         |
+---------------------------------+
|所有人不可见                     |
+---------------------------------+
|只对部分人可见                   |
+---------------------------------+

其中「只对部分人可见」选项可以分组或用户为单位进行任意的权限指派。

应用的可见性权限与访问权限一致，在此不再赘述。

应用权限
''''''''

一账通为第三方应用提供了精细的权限控制。除了基本的访问（登录）权限之外，管理员还可以为应用额外添加任意的自定义权限，并为它们指定可访问的用户和分组。

管理员可通过账号管理或分组管理中特定用户的「应用内权限」操作来查看该用户的应用权限一览表并直接进行以个人为粒度的权限配置（通过更改默认的权限继承策略）。

.. figure:: assets/账号权限管理-分组权限管理.*
   :align: center

   账号权限管理 & 分组权限管理

更为全面的权限配置可以通过「应用管理」页面下特定应用的「权限管理」操作来进行。管理员可以在此为应用添加自定义权限，配置用户或分组的白/黑名单策略，以及查看根据当前配置计算得出的最终授权名单并分析其中用户的授权来源。

.. figure:: assets/应用权限管理.*
   :align: center

   应用权限管理

.. important::
      自定义权限在一账通中仅仅是一个唯一的权限 ID，第三方应用可根据此 ID 通过 HTTP API 向一账通查询特定的用户是否拥有该权限。在此情况下，一账通仅仅是在利用已有的分组–权限架构，作为一个权限子系统来检查特定的权限断言，而并不会实际涉及权限的具体内容。

子管理员
........

管理员可在「子管理员」页面下添加子管理员。子管理员可以在一个指定的范围（分组，用户以及应用）下行使受限的权力。

.. figure:: assets/子管理员.*
   :align: center

   子管理员

.. TODO:
   权限的详细定义

其他
....

登录页面配置
''''''''''''

管理员可在「配置管理」页面下为公司进行基本的登录页面配置。

.. figure:: assets/配置管理.*
   :align: center

   配置管理

操作日志
''''''''

管理员可在「操作日志」页面下查看并检索详细的用户及管理员活动日志。

.. figure:: assets/操作日志.*
   :align: center

   操作日志

.. _树: https://en.wikipedia.org/wiki/Tree_(graph_theory)
.. _森林: https://en.wikipedia.org/wiki/Tree_(graph_theory)#Forest

使用 HTTP API 接口
------------------

例：使用 HTTPie 命令行工具进行权限管理
::::::::::::::::::::::::::::::::::::::

例：使用 Python 脚本进行第三方应用接入
::::::::::::::::::::::::::::::::::::::
.. ASYNC CROSS REFERENCE:
   第三方接入

第三方应用接入
==============

OAuth2.0
--------

OAuth2.0 是一种被广泛使用的授权协议。一账通选择通过 `OAuthLib`_ 提供对 OAuth2.0 的支持，允许第三方应用使用 OAuth2.0 进行单点登录认证。

OAuth2.0 定义了四个角色、两种客户端类型、四种授权类型以及三个协议端点，其中只有某些特定组合是有效的。其中部分授权流程所需要的重定向端点需由认证客户端（即第三方应用）提供。本文将解释部分概念并给出所有许可类型对应的的实际流程。

概念介绍
::::::::

本节将稍微侧重于使用一种「面向端点」而非常规的「面向授权流程」的叙事视角，以端点规格为基准给出四种许可类型及其对应的授权流程的精确定义。

.. glossary::
   角色
      资源所有者（Resource Owner）
         该角色有能力授权访问受保护的资源，当其为个人时一般被称为终端用户（End User）。在一账通中即为有权登录的用户。
      客户端（Client）
         通过资源所有者给予的授权许可访问受保护资源的程序。在一账通中为接入的第三方应用。
      授权服务器（Authorization Server）
         验证资源所有者的授权许可与客户端身份的有效性并最终签发访问受保护资源的令牌的服务。在一账通中即为提供单点登录服务的一账通实例。
      资源服务器（Resource Server）
         能够识别授权服务器所签发的令牌并依此提供受保护的资源的服务。由于一账通中的「资源」仅有登录用户信息一种，因此也直接存在于一账通实例中。

抽象授权流程
   .. code-block::

      +--------+                               +---------------+
      |        |--(A)- Authorization Request ->|   Resource    |
      |        |                               |     Owner     |
      |        |<-(B)-- Authorization Grant ---|               |
      |        |                               +---------------+
      |        |
      |        |                               +---------------+
      |        |--(C)-- Authorization Grant -->| Authorization |
      | Client |                               |     Server    |
      |        |<-(D)----- Access Token -------|               |
      |        |                               +---------------+
      |        |
      |        |                               +---------------+
      |        |--(E)----- Access Token ------>|    Resource   |
      |        |                               |     Server    |
      |        |<-(F)--- Protected Resource ---|               |
      +--------+                               +---------------+

   (A) 客户端向资源所有者发起授权请求（Authorization Request）
   (#) 资源所有者向客户端签发授权许可（Authorization Grant），它是表示资源所有者同意授权的凭据，使用下述四种许可类型（Grant Type）中的一种。
   (#) 客户端向授权服务器认证身份并凭借授权许可换取访问令牌（Access Token）
   (#) 授权服务器验证客户端身份及授权许可的有效性并对有效的请求签发令牌
   (#) 客户端凭借访问令牌向资源服务器请求受保护的资源
   (#) 资源服务器校验令牌的有效性并响应有效的请求

.. glossary::
   客户端类型
      公开（Public）
         此类客户端没有能力保存自身的凭据（``client_secret`` 或用户名与口令），如基于 UA 的应用或本地应用。
      机密（Confidential）
         此类客户端有责任且有能力安全地保存自身的凭据，如配置正确的服务端应用。

   其他概念
      此处描述了一些未在 RFC6749 中精确定义但被普遍接受的名词及其中文试译。

      用户代理（User-Agent）
         辅助用户与 Web 应用沟通并代理用户操作的程序，一般为浏览器。
      基于 UA 的应用（UA-based Application）
         即基于浏览器的 Web 应用，自身没有任何手段防止凭据泄露。
      本地应用（Native Application）
         运行在属于资源所有者的设备上的客户端应用，同样因处于不可信的环境中而无法防止凭据泄露。
      服务端应用（Server Application）
         运行在服务器中的应用，因为环境可控而在正确配置了安全策略的情况下有能力保存自身的安全凭据。

   协议端点
      授权端点（Authorization Endpoint）
         由授权服务器提供，用于辅助客户端取得授权许可，仅存在于下述的授权码许可流程与隐式许可流程中。
      重定向端点（Redirection Endpoint）
         由客户端提供，对于公开客户端或使用隐式许可的机密客户端为必需项 [#f2]_，用于授权请求认证通过后将页面从授权服务器转回客户端程序并附带客户端凭据（授权码或令牌），仅存在于授权码许可流程与隐式许可流程中。
      令牌端点（Token Endpoint）
         由授权服务器提供，用于验证客户端凭据并签发令牌。存在于除隐式许可流程之外的所有许可流程中。

         身份认证
            公开客户端在访问令牌端点时必须附带自身的 ``client_id`` 参数作为标识，机密客户端在条件允许时 *应当* 使用 `HTTP Basic Authentication`_ 或类似的机制附带自身的 ``client_id`` 与 ``client_secret`` 以认证客户端身份，在不得已的情况下可以作为参数附带两者。

   许可类型
      授权码许可（Authorization Code Grant）
         该许可类型功能最为完整、最为常见且安全，它要求客户端首先在授权端点获得授权码作为授权许可，然后在令牌端点凭授权码换取令牌。
      隐式许可（Implicit Grant）
         该许可类型在授权端点直接签发令牌而不使用授权码，但不签发刷新令牌（Refresh Token）以防止滥用。因此可以认为该类型的授权许可是「隐式」的。公开客户端仅可使用以上两类许可流程进行授权。
      资源所有者口令凭据许可（Resource Owner Password Credentials Grant）
         该许可类型直接使用资源所有者的用户名与口令在令牌端点换取令牌，仅适用于授权服务器高度信任客户端的情况。即使在此种情况下，客户端也不应该保存资源所有者的凭据，而是通过长时效的访问令牌或刷新令牌取而代之。
      客户端凭据许可（Client Credentials Grant）
         该许可类型面向客户端是被信任的机器而不涉及人类用户的情况，因为机密客户端访问令牌端点需经身份认证，使用此种许可类型的客户端可以在令牌端点直接换取令牌。

端点规格
::::::::

本节部分内容为实现所定义（如权限的类型），并未在 RFC6749 中详细说明。

.. TODO:
   footnotes for open redirector and xsrf

.. TODO:
   More custom blocks (e.g. Defined by Impl)

授权端点
   方法
      * GET

   参数类型
      * URI `Query Component`_

   参数
      ================= ======== =========================================
      参数名             存在性   说明
      ----------------- -------- -----------------------------------------
      ``client_id``     必选     客户端标识
      ``response_type`` 必选     许可类型（授权码许可或隐式许可）
      ``redirect_uri``  可选     取代默认重定向端点
      ``scope``         可选     指定授权范围，默认请求所有权限
      ``state``         可选     自定义状态，用于客户端内部状态保持 [#f3]_
      ================= ======== =========================================

   参数取值
      ``response_type``
         ========== ================================
         取值        意义
         ---------- --------------------------------
         ``code``   指定授权码许可流程（返回授权码）
         ``token``  指定隐式许可流程（返回令牌）
         ========== ================================

      ``scope``
         *在一账通中*，该参数的格式为一个用空格分割的字符串，其中每一项都代表了一类权限。

         ========= =============
         权限        意义
         --------- -------------
         ``read``   查询用户信息
         ``write``  更改用户信息
         ========= =============

   重定向参数
      ================= ============ =============
      参数名              存在性         说明
      ----------------- ------------ -------------
      ``code``           授权码许可     授权码
      ``access_token``   隐式许可       访问令牌
      ``expires_in``     隐式许可       令牌有效期
      ``token_type``     隐式许可       令牌类型
      ``scope``          依请求         授权范围
      ``state``          依请求         自定义状态
      ================= ============ =============

.. TODO:
   token-type spec?

.. TODO:
   Para client_* list

重定向端点
   * 必须是 `Absolute URI`_。
   * 允许 `Query Component`_，并且加入新参数时原有的参数部分不能丢失。
   * 不允许 `Fragment Component`_。

令牌端点
   方法
      POST

   参数类型
      x-www-form-urlencoded

   参数
      ================= ========================= =============================
      参数名              存在性                    说明
      ----------------- ------------------------- -----------------------------
      ``grant_type``     必选                      许可类型
      ``code``           授权码许可                 授权码
      ``username``       资源所有者口令凭据许可       用户名（即一账通用户名）
      ``password``       资源所有者口令凭据许可       口令（即一账通密码）
      ``refresh_token``  刷新令牌                   刷新令牌
      ``redirect_uri``   授权码许可 && 依请求        校验重定向端点 [#f4]_
      ``client_id``      部分客户端                 客户端标识
      ``client_secret``  部分机密客户端              客户端凭据
      ================= ========================= =============================

   参数取值
      ``grant_type``

         ======================= ================================
         取值                      意义
         ----------------------- --------------------------------
         ``authorization_code``   授权码许可流程指定
         ``password``             资源所有者口令凭据许可流程指定
         ``client_credentials``   客户端凭据许可流程指定
         ``refresh_token``        刷新令牌指定
         ======================= ================================

   返回值
      令牌端点的返回值为JSON格式的响应体。

      ================== ==========================
      键名                说明
      ------------------ --------------------------
      ``access_token``   访问令牌
      ``refresh_token``  刷新令牌
      ``token_type``     令牌类型
      ``expires_in``     访问令牌过期时间（秒）
      ``scope``          令牌的最终授权范围 [#f5]_
      ================== ==========================


.. TODO:
   把Grant Flow讲清楚摆上去
   详细定义参数之间的联系
   完备阐述scope与state

.. seealso::
   * `RFC6749`_ 是 OAuth2.0 的规范文档
   * 更多由实现定义的细节可参考 `OAuthLib Documentation`_
   * `OAuth 2.0 筆記`_ 是一系列极佳的关于 OAuth2.0 具体授权流程的第三方文章

关于一账通
::::::::::

第三方应用需在向一账通实例的管理员申请 OAuth2.0 接入的同时指定自身的客户端类型（在一账通中写作 ``client_type``）、许可类型（在一账通中写作 ``authorization_grant_type``）以及重定向端点地址（在一账通中写作 ``redirect_uris``）并由管理员进行相关配置，完成之后管理员会提供给第三方应用自身的 ``client_id``、``client_secret`` 以及授权与令牌端点地址，以及一个额外的可用令牌访问的用户信息端点作为资源。

.. figure:: assets/应用管理-接口详情.*
   :align: center
   
   协议接口详情

授权码许可流程详解
::::::::::::::::::

.. TODO:
   理论说明 + ASCII 图片 in RFC6749

   * 第一步，客户端向授权端点发送 HTTP GET 请求，指定 URI 参数 ``response_type`` 为 ``code`` 并附带自身 ``client_id`` 作为参数。

   .. code-block:: bash
      http -F get https://YOUR_ARK_ID_INSTANCE_HOSTNAME/oauth/authorize/ \
      response_type==code client_id==YOUR_CLIENT_ID

   此时授权端点会返回 HTTP 302 并跳转到一账通的授权界面，如果用户尚未登录一账通，可能会被要求登录。在用户确认授权之后一账通会重定向到应用所指定的重定向端点，形如

   .. code-block::
      YOUR_REDIRECTION_ENDPOINT_SCHEMA/?code=RANDOM_AUTHORIZATION_CODE

   * 第二步，应用响应该请求并从 URI 中提取授权码。

   * 第三步，应用通过 HTTP 表单向令牌端点 POST 得到的授权码并指定 ``grant_type`` 为 ``authorization_code``。如果是公开客户端，可以附带 ``client_id`` 以标识身份。如果是机密客户端，推荐使用 HTTP Basic Auth 传输 ``client_id`` 与 ``client_secret``。

   .. code-block:: bash
      http -a YOUR_CLIENT_ID:YOUR_CLIENT_SECRET \
      -f POST https://YOUR_ARK_ID_INSTANCE_HOSTNAME/oauth/token/ \
      grant_type=authorization_code code=RANDOM_AUTHORIZATION_CODE

   此时令牌端点会返回一个含有访问令牌与刷新令牌的 JSON 响应：

   .. code-block:: json
      {
          "access_token": "YOUR_ACCESS_TOKEN",
          "expires_in": 36000,
          "refresh_token": "YOUR_REFRESH_TOKEN",
          "scope": "read write",
          "token_type": "Bearer"
      }

   其中 ``token_type`` 说明这是一个简单的 `Bearer 令牌`_，可以通过在请求头中加入 ``Authorization: 'Bearer your_access_token'`` 来访问受保护的资源。

   * 通过访问资源服务器（一账通界面中的身份信息地址），此应用可以读写（依权限而定）当前登录用户的用户信息了：

   .. code-block:: bash
      http -f -F get  https://YOUR_ARK_ID_INSTANCE_HOSTNAME/oauth/userinfo \
      Authorization:'Bearer YOUR_ACCESS_TOKEN'

   * 刷新一个已经过期了的访问令牌以得到新的访问令牌与刷新令牌是容易的：

   .. code-block:: bash
      http -a YOUR_CLIENT_ID:YOUR_CLIENT_SECRET \
      -f POST https://YOUR_ARK_ID_INSTANCE_HOSTNAME/oauth/token/ \
      grant_type=refresh_token refresh_token=YOUR_REFRESH_TOKEN

.. TODO:
   用户信息规格说明


隐式许可流程详解
::::::::::::::::

资源所有者口令凭据许可流程详解
::::::::::::::::::::::::::::::

客户端凭据许可流程详解
::::::::::::::::::::::

注
::

.. GLOBAL TODO:
   Using footnotes instead of parentheses

.. [#f2] 在一账通中全部模式必选，但并不实际生效

.. _RFC6749: https://github.com/jeansfish/RFC6749.zh-cn
.. _OAuthLib: https://github.com/oauthlib/oauthlib
.. _OAuthLib Documentation: https://oauthlib.readthedocs.io/en/latest/index.html
.. _HTTP Basic Authentication: https://tools.ietf.org/html/rfc7617
.. _Bearer 令牌: https://tools.ietf.org/html/rfc6750

.. _OAuth 2.0 筆記: https://blog.yorkxin.org/2013/09/30/oauth2-1-introduction.html

.. _Absolute URI: https://tools.ietf.org/html/rfc3986#section-4.3
.. _Query Component: https://tools.ietf.org/html/rfc3986#section-3.4
.. _Fragment Component: https://tools.ietf.org/html/rfc3986#section-3.5

LDAP
----

HTTP API
--------

\*一账通架构解析
=================

\*二次开发指南
===============

贡献指南
===============

如果你在使用一账通的过程中遇到了 bug，或者期望某个一账通现在还不支持的特性，欢迎你在 `一账通 issue 主页`_  提出宝贵的意见和建议。
如果你顺手修复了这个 bug，或者实现了这个特性，为了使你的工作能让更多人受益，也为了避免你的代码与一账通的后续开发产生冲突，请按照 Fork -> Patch -> Push -> Pull Request 的流程来和大家分享你的代码。

.. attention::
   在提交 issue 或 pull request 之前请务必阅读以下内容。
   
   :Bug:
      在提 issue 之前，请先搜索一下同样的 bug 是否已经被反馈过了。如果没有，请创建一个新的 issue并反馈遇到此问题的环境、背景，以及如何复现这个 bug。详细、准确的描述可以加快问题解决的速度。
   :特性:
      同样的，在提 issue 之前，请先搜索一下同样的特性是否已经被反馈过了。如果没有，请创建一个新的 issue来说明为什么需要这个特性，以及该特性的具体细节。一账通的开发人员将视此特性的需求程度排期实现。
   :Pull Request:
      * 改动的内容需遵守代码风格检查，并通过所有的测试。CI 将会自动执行这个检测，无论是成功或失败都会在 commit 上标注。检测不通过的 pull request 不会被合并。
      * 本地开发时，如果环境装有 docker，可以通过 ``make ci`` 的命令自行检查。如果没有可以通过 ``make lint test`` 代替。

.. _一账通 issue 主页: https://github.com/longguikeji/arkid-core/issues
