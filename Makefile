INVENTORY := ansible/inventory.ini
#ARGS := --check --diff
ARGS := --diff

ANSIBLE := ANSIBLE_STDOUT_CALLBACK=debug ansible-playbook


all:

clean:


setup-basic:
	$(ANSIBLE) -i $(INVENTORY) $(ARGS) ansible/setup_basic.yml

setup-kubernetes:
	$(ANSIBLE) -i $(INVENTORY) $(ARGS) ansible/setup_kubernetes.yml

