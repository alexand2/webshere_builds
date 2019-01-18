FROM websphere-liberty
COPY jvm.options /config/jvm.options
USER 0
RUN  chmod 777 -R /opt/ibm/wlp/ /logs
USER 10001
