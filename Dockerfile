FROM centos:7.9.2009

EXPOSE 443/tcp 80/tcp

ENV SHIBBOLETH_VERSION="3.4.1-1" \
    APACHE_VERSION="2.4.6-99.el7.centos.1"

RUN yum -y update && yum -y install wget && wget --no-check-certificate https://shibboleth.net/cgi-bin/sp_repo.cgi?platform=CentOS_7 -O /etc/yum.repos.d/shibboleth.repo && yum -y install httpd-${APACHE_VERSION} mod_ssl shibboleth-${SHIBBOLETH_VERSION} && yum -y clean all

RUN echo "export LD_LIBRARY_PATH=/opt/shibboleth/lib64:$LD_LIBRARY_PATH" >> /etc/sysconfig/shibd && echo "export SHIBD_USER=shibd" >> /etc/sysconfig/shibd && sed -i -e "s|log4j.appender.shibd_log=.*$|log4j.appender.shibd_log=org.apache.log4j.ConsoleAppender|" -e "s|log4j.appender.warn_log=.*$|log4j.appender.warn_log=org.apache.log4j.ConsoleAppender|" -e "s|log4j.appender.tran_log=.*$|log4j.appender.tran_log=org.apache.log4j.ConsoleAppender|" -e "s|log4j.appender.sig_log=.*$|log4j.appender.sig_log=org.apache.log4j.ConsoleAppender|" /etc/shibboleth/shibd.logger

RUN sed -i -r -e "s|^(\s*ErrorLog)\s+\S+|\1 /dev/stderr|" -e 's|^(\s*CustomLog)\s+\S+\s+(.*$)|\1 /dev/stdout \2 env=\!dontlog|' /etc/httpd/conf/httpd.conf && echo "ServerSignature Off" >> /etc/httpd/conf/httpd.conf && echo "ServerTokens Prod" >> /etc/httpd/conf/httpd.conf && rm -f /etc/httpd/conf.d/{autoindex.conf,welcome.conf}

# RUN sed -i '$aHTTPD_LANG=en_US.UTF-8' /etc/sysconfig/httpd
RUN sed -i -e "s/LANG=C/LANG=en_US.UTF-8/" /etc/sysconfig/httpd

COPY httpd-shibd-foreground /usr/local/bin/

RUN chmod +x /usr/local/bin/httpd-shibd-foreground

CMD ["httpd-shibd-foreground"]
