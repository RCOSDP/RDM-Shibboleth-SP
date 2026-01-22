FROM centos:7.9.2009

EXPOSE 443/tcp 80/tcp

ENV SHIBBOLETH_VERSION="3.4.1-1" \
    APACHE_VERSION="24u"

COPY CentOS-Base.repo /etc/yum.repos.d/

RUN yum clean all

RUN yum -y update && yum -y install wget && wget --no-check-certificate https://shibboleth.net/cgi-bin/sp_repo.cgi?platform=CentOS_7 -O /etc/yum.repos.d/shibboleth.repo && yum -y install epel-release && yum -y install https://vault.ius.io/el7/x86_64/packages/a/apr15u-1.5.2-2.ius.el7.x86_64.rpm https://vault.ius.io/el7/x86_64/packages/a/apr15u-util-1.5.4-3.ius.el7.x86_64.rpm https://vault.ius.io/el7/x86_64/packages/h/httpd24u-filesystem-2.4.58-1.el7.ius.noarch.rpm https://vault.ius.io/el7/x86_64/packages/h/httpd24u-tools-2.4.58-1.el7.ius.x86_64.rpm https://vault.ius.io/el7/x86_64/packages/h/httpd24u-2.4.58-1.el7.ius.x86_64.rpm https://vault.ius.io/el7/x86_64/packages/h/httpd24u-mod_ssl-2.4.58-1.el7.ius.x86_64.rpm shibboleth-${SHIBBOLETH_VERSION} && yum -y clean all

RUN echo "export LD_LIBRARY_PATH=/opt/shibboleth/lib64:$LD_LIBRARY_PATH" >> /etc/sysconfig/shibd && echo "export SHIBD_USER=shibd" >> /etc/sysconfig/shibd && sed -i -e "s|log4j.appender.shibd_log=.*$|log4j.appender.shibd_log=org.apache.log4j.ConsoleAppender|" -e "s|log4j.appender.warn_log=.*$|log4j.appender.warn_log=org.apache.log4j.ConsoleAppender|" -e "s|log4j.appender.tran_log=.*$|log4j.appender.tran_log=org.apache.log4j.ConsoleAppender|" -e "s|log4j.appender.sig_log=.*$|log4j.appender.sig_log=org.apache.log4j.ConsoleAppender|" /etc/shibboleth/shibd.logger

RUN sed -i -r -e "s|^(\s*ErrorLog)\s+\S+|\1 /dev/stderr|" -e 's|^(\s*CustomLog)\s+\S+\s+(.*$)|\1 /dev/stdout \2 env=\!dontlog|' /etc/httpd/conf/httpd.conf && echo "ServerSignature Off" >> /etc/httpd/conf/httpd.conf && echo "ServerTokens Prod" >> /etc/httpd/conf/httpd.conf && rm -f /etc/httpd/conf.d/{autoindex.conf,welcome.conf}

# RUN sed -i '$aHTTPD_LANG=en_US.UTF-8' /etc/sysconfig/httpd
RUN sed -i -e "s/LANG=C/LANG=en_US.UTF-8/" /etc/sysconfig/httpd

COPY mdq-cert.pem /etc/shibboleth/

COPY httpd-shibd-foreground /usr/local/bin/

RUN chmod +x /usr/local/bin/httpd-shibd-foreground

CMD ["httpd-shibd-foreground"]
