FROM centos:latest

# Install java and other misc packages
RUN yum update -y && \
yum install -y wget sudo && \
yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel && \
yum clean all

# Install spark
RUN mkdir -p /opt/apache
RUN curl -s http://apache.osuosl.org/spark/spark-2.2.1/spark-2.2.1-bin-hadoop2.7.tgz | tar xz -C /opt/apache
RUN ln -s /opt/apache/spark-* /opt/apache/spark; mkdir -p /etc/spark; ln -s /opt/apache/spark/conf /etc/spark/conf
ADD spark-defaults.conf spark-env.sh /etc/spark/conf/
ADD hadoop /opt/apache/spark/bin

# Install pip and other packages
RUN curl https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py
RUN python /tmp/get-pip.py
RUN pip install supervisor
ADD supervisord.conf /etc

# Install R
RUN yum install -y epel-release && \
yum install -y R && \
yum install -y git xml2 libxml2-devel curl curl-devel openssl-devel pandoc libcurl-devel && \
yum clean all

# Set env
ENV TERM xterm
ENV PATH $PATH:/opt/apache/spark/bin
ENV SPARK_HOME /opt/apache/spark
ADD bootstrap.sh /etc/bootstrap.sh
CMD ["/etc/bootstrap.sh"]
