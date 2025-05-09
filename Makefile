INVENTORY := ansible/inventory.ini
#ARGS := --check --diff
ARGS := --diff

ANSIBLE := ANSIBLE_STDOUT_CALLBACK=debug ansible-playbook
HELM_INSTALL := helm upgrade --install --debug --atomic --wait

include scripts/Makefile.deploy.mk


all:

clean:


# creates a SSH key used to connect with the target machine
~/.ssh/id_rsa:
	mkdir -p ~/.ssh/
	ssh-keygen -t rsa -b 4096 -C "RPCloud SSH Key" -f ~/.ssh/id_rsa
	chmod 600 ~/.ssh/id_rsa
	chmod 600 ~/.ssh/id_rsa.pub

# performs the actual copy operation and stores a cookie file
~/.ssh/id_rsa.rpcloud.cookie: ~/.ssh/id_rsa
	ssh-copy-id ubuntu@rpcloud
	touch ~/.ssh/id_rsa.rpcloud.cookie

# creates a SSH Key and copies onto the target machine
connect-ssh: ~/.ssh/id_rsa.rpcloud.cookie

# copies the kubernetes config file from the node to the local user folder
~/.kube/config: ~/.ssh/id_rsa.rpcloud.cookie
	mkdir -p ~/.kube/

	# kubernetes
	if ssh ubuntu@rpcloud "sudo cat /etc/kubernetes/admin.conf"; then \
		ssh ubuntu@rpcloud "sudo cat /etc/kubernetes/admin.conf" > ~/.kube/config; \
	fi

	# k3s
	if ssh ubuntu@rpcloud "sudo test -f /etc/rancher/k3s/k3s.yaml"; then \
		ssh ubuntu@rpcloud "sudo cat /etc/rancher/k3s/k3s.yaml" > ~/.kube/config; \
		sed -i 's|server: https://127.0.0.1:\([0-9]\+\)|server: https://rpcloud:\1|' ~/.kube/config; \
	fi

	# fail if the config file was not downloaded
	test -f ~/.kube/config

connect-kubernetes: ~/.kube/config


setup-basic:
	$(ANSIBLE) -i $(INVENTORY) $(ARGS) ansible/setup_basic.yml

setup-avahi:
	$(ANSIBLE) -i $(INVENTORY) $(ARGS) ansible/setup_avahi.yml

setup-containerd:
	$(ANSIBLE) -i $(INVENTORY) $(ARGS) ansible/setup_containerd.yml

setup-kubernetes-full:
	$(ANSIBLE) -i $(INVENTORY) $(ARGS) ansible/setup_kubernetes_full.yml

setup-kubernetes-k3s:
	$(ANSIBLE) -i $(INVENTORY) $(ARGS) ansible/setup_kubernetes_k3s.yml


reset-cluster:
	./scripts/reset-cluster.sh | tee logs/reset.log



browse-longhorn:
	kubectl port-forward service/longhorn-frontend 8080:80 -n longhorn-system


browse-dashboard:
	kubectl port-forward service/kubernetes-dashboard-kong-proxy 8443:443 -n kubernetes-dashboard


browse-phpldapadmin:
	kubectl port-forward service/openldap-phpldapadmin 8080:80 -n openldap
