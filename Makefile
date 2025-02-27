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

reset-cluster:
	@echo "WARNING: This will completely reset the Kubernetes cluster!"
	@read -p "Are you sure you want to proceed? (yes/no) " answer; \
	if [ "$$answer" = "yes" ]; then \
		./scripts/reset-cluster.sh; \
	else \
		echo "Operation cancelled."; \
		exit 1; \
	fi
