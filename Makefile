INVENTORY := ansible/inventory.ini
#ARGS := --check --diff
ARGS := --diff

ANSIBLE := ANSIBLE_STDOUT_CALLBACK=debug ansible-playbook
HELM_INSTALL := helm upgrade --install --debug --atomic --wait


all:

clean:


# creates a SSH key used to connect with the target machine
~/.ssh/id_rsa:
	mkdir -p ~/.ssh/
	ssh-keygen -t rsa -b 4096 -C "RPCloud SSH Key" -f ~/.ssh/id_rsa
	chmod 600 ~/.ssh/id_rsa
	chmod 600 ~/.ssh/id_rsa.pub

# creates a SSH Key and copies onto the target machine
connect-ssh: ~/.ssh/id_rsa
	ssh-copy-id ubuntu@rpcloud

# copies the kubernetes config file from the node to the local user folder
~/.kube/config: connect-ssh
	mkdir -p ~/.kube/
	ssh ubuntu@rpcloud "sudo cat /etc/kubernetes/admin.conf" > ~/.kube/config

connect-kubernetes: ~/.kube/config


setup-basic:
	$(ANSIBLE) -i $(INVENTORY) $(ARGS) ansible/setup_basic.yml

setup-avahi:
	$(ANSIBLE) -i $(INVENTORY) $(ARGS) ansible/setup_avahi.yml

setup-containerd:
	$(ANSIBLE) -i $(INVENTORY) $(ARGS) ansible/setup_containerd.yml

setup-kubernetes:
	$(ANSIBLE) -i $(INVENTORY) $(ARGS) ansible/setup_kubernetes.yml

deploy:
	./scripts/deploy.sh | tee logs/deploy.log


deploy-gitea:
	helm repo add gitea-charts https://dl.gitea.com/charts/
	$(HELM_INSTALL) gitea gitea-charts/gitea --create-namespace --namespace gitea


reset-cluster:
	./scripts/reset-cluster.sh | tee logs/reset.log



browse-longhorn:
	kubectl port-forward service/longhorn-frontend 8080:80 -n longhorn-system


browse-dashboard:
	kubectl port-forward service/kubernetes-dashboard-kong-proxy 8443:443 -n kubernetes-dashboard


dashboard-token:
	kubectl -n kubernetes-dashboard create token admin-user
