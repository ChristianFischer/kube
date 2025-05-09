include $(dir $(realpath $(lastword $(MAKEFILE_LIST))))/Makefile.colors.mk

HELM_INSTALL := "helm upgrade --install --debug --atomic --wait"
KUBE_APPLY   := kubectl apply


# Add Helm repositories
helm-add-repos:
	echo -e "${TEXT_GREEN}Adding Helm repositories...${TEXT_RESET}"
	helm repo add flannel https://flannel-io.github.io/flannel/
	helm repo add jetstack https://charts.jetstack.io
	helm repo add traefik https://helm.traefik.io/traefik
	helm repo add projectcalico https://docs.tigera.io/calico/charts
	helm repo add longhorn https://charts.longhorn.io
	helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
	helm repo add helm-openldap https://jp-gouin.github.io/helm-openldap/
	helm repo add gitea-charts https://dl.gitea.com/charts/
	helm repo update

# Deploy Longhorn
deploy-longhorn:
	echo -e "${TEXT_GREEN}Deploying Longhorn...${TEXT_RESET}"
	$(HELM_INSTALL) longhorn longhorn/longhorn \
			--namespace longhorn-system \
			--create-namespace \
			-f helm/longhorn-values.yaml

# Deploy Flannel CNI
deploy-flannel:
	$(HELM_INSTALL) flannel flannel/flannel \
			--set podCidr="10.244.0.0/16" \
			--namespace kube-flannel \
			--create-namespace

# Deploy Cert Manager
deploy-cert-manager:
	$(HELM_INSTALL) cert-manager jetstack/cert-manager \
			--version v1.17.0 \
			--namespace cert-manager \
			--create-namespace \
			-f helm/cert-manager-values.yaml

# Deploy Traefik Ingress Controller
deploy-traefik:
	$(HELM_INSTALL) traefik traefik/traefik \
			--namespace kube-system \
			-f helm/traefik-values.yaml

# Deploy Kubernetes Dashboard (Helm Chart)
deploy-kubernetes-dashboard-helmchart:
	$(HELM_INSTALL) kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
			--namespace kubernetes-dashboard \
			--create-namespace \
			-f helm/kubernetes-dashboard-values.yaml

# Deploy Kubernetes Dashboard (Ingress Route)
deploy-kubernetes-dashboard-ingress:
	$(KUBE_APPLY) -f manifests/ingress/kubernetes-dashboard.yml

# Deploy admin user for dashboard
deploy-kubernetes-dashboard-admin-user:
	$(KUBE_APPLY) -f manifests/auth/dashboard-admin-user.yml

# Deploy Kubernetes Dashboard
deploy-kubernetes-dashboard: \
	deploy-kubernetes-dashboard-helmchart \
	deploy-kubernetes-dashboard-admin-user \
	deploy-kubernetes-dashboard-ingress

# Get token for dashboard
kubernetes-dashboard-token:
	kubectl -n kubernetes-dashboard create token admin-user


# Deploy OpenLDAP + phpldapadmin
deploy-openldap:
	$(HELM_INSTALL) openldap helm-openldap/openldap-stack-ha \
			--namespace openldap \
			--create-namespace \
			-f helm/openldap-values.yml


# Deploy self-signed certificate
deploy-selfsigned-ca:
	$(KUBE_APPLY) -f manifests/clusterissuer/rpcloud-selfsigned.yml


# Deploy Gitea
deploy-gitea:
	$(HELM_INSTALL) gitea gitea-charts/gitea \
		--namespace gitea \
		--create-namespace


deploy: \
	helm-add-repos \
	deploy-flannel \
	deploy-cert-manager \
	deploy-selfsigned-ca \
	deploy-longhorn \
	deploy-traefik \
	deploy-openldap \
	deploy-gitea \

	echo "Finished Deploying"
