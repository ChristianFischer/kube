INVENTORY := ansible/inventory.ini
#ARGS := --check --diff
ARGS := --diff

ANSIBLE := ANSIBLE_STDOUT_CALLBACK=debug ansible-playbook


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
	ssh ubuntu@rpcloud "sudo cat /etc/kubernetes/admin.conf" > ~/.kube/config

connect-kubernetes: ~/.kube/config


setup-basic:
	$(ANSIBLE) -i $(INVENTORY) $(ARGS) ansible/setup_basic.yml

setup-avahi:
	$(ANSIBLE) -i $(INVENTORY) $(ARGS) ansible/setup_avahi.yml

setup-kubernetes:
	$(ANSIBLE) -i $(INVENTORY) $(ARGS) ansible/setup_kubernetes.yml

deploy:
	./scripts/deploy.sh

reset-cluster:
	./scripts/reset-cluster.sh
