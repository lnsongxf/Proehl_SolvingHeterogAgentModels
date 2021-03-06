% This is code for the working paper "Approximating Equilibria with Ex-Post 
% Heterogeneity and Aggregate Risk" by Elisabeth Pr�hl
%
% AUTHOR Elisabeth Pr�hl, University of Geneva and Swiss Finance Institute
% DATE May 2018
%
% DESCRIPTION
% This function computes the first-order conditions to solve for in the
% proximal point algorithm with aggregate shocks.
%__________________________________________________________________________
function [f,J] = FOC_AggShock(sol,k_prime,c,y,agK_m,grid,m,StaticParams,Sol,Poly,agK_prime_new_dk,c_pr_der)

sol_k = reshape(sol,size(k_prime'))';

sol_k_large = interp1(StaticParams.kGrid_pol,sol_k',StaticParams.kGrid)';   
[agK_prime_new,weights_new] = calcAggregates(sol_k_large,grid,StaticParams,Poly);

rate_prime = @(z_idx)...
   StaticParams.alpha.*...
   repmat([1-StaticParams.delta_a*[1;1];1+StaticParams.delta_a*[1;1]],[1,length(StaticParams.kGrid_pol)])...
   .*repmat(agK_prime_new((z_idx>2)+1),[4,length(StaticParams.kGrid_pol)]).^(StaticParams.alpha-1)...
   ./(StaticParams.l_bar.*repmat([StaticParams.er(1)*[1;1];StaticParams.er(2)*[1;1]],[1,length(StaticParams.kGrid_pol)]))...
   .^(StaticParams.alpha-1); 
rate_prime_der = @(z_idx)...
   StaticParams.alpha.*(StaticParams.alpha-1).*...
   repmat([1-StaticParams.delta_a*[1;1];1+StaticParams.delta_a*[1;1]],[1,length(StaticParams.kGrid_pol)])...
   .*repmat(agK_prime_new((z_idx>2)+1),[4,length(StaticParams.kGrid_pol)]).^(StaticParams.alpha-2)...
   ./((StaticParams.l_bar.*repmat([StaticParams.er(1)*[1;1];StaticParams.er(2)*[1;1]],[1,length(StaticParams.kGrid_pol)]))...
   .^(StaticParams.alpha-1));

c_prime = @(z_idx,z,k,w)...
           interp1(StaticParams.kGrid_pol,...
           getCApprox(Sol.distrGrid,squeeze(c(:,2*z(1)+z(2)+1,:)),...
           Sol.idx,squeeze(w((z_idx>2)+1,z(1)+1,:))'),...
           max(StaticParams.k_min,k),'linear','extrap');
c_pr = zeros([4,size(c,2),size(c,3)]);
for z_idx=1:4
    c_pr(z_idx,:,:) = [c_prime(z_idx,[0,0],sol_k(z_idx,:),weights_new);...
                       c_prime(z_idx,[0,1],sol_k(z_idx,:),weights_new);...
                       c_prime(z_idx,[1,0],sol_k(z_idx,:),weights_new);...
                       c_prime(z_idx,[1,1],sol_k(z_idx,:),weights_new)] ;
end   

f_foc_k = @(z_idx)...
         (squeeze(Sol.wealth(agK_m,z_idx,:))'-sol_k(z_idx,:)).^(-StaticParams.gamma)...
         -StaticParams.beta*(StaticParams.P(z_idx,:)*...
          ((1-StaticParams.delta+rate_prime(z_idx))...
         .*squeeze(c_pr(z_idx,:,:)).^(-StaticParams.gamma)))...
         +1/m*(sol_k(z_idx,:)-k_prime(z_idx,:))...
         +(sol_k(z_idx,:)<=y(z_idx,:)/m).*(-y(z_idx,:)+m*(sol_k(z_idx,:)));
f_foc_k_dk_term1 = @(z_idx)...
        -StaticParams.beta*(StaticParams.P(z_idx,:)*...
         ((rate_prime_der(z_idx).*squeeze(agK_prime_new_dk(2-mod(z_idx,2),(z_idx>2)+ones(1,4),:)))...
         .*squeeze(c_pr(z_idx,:,:)).^(-StaticParams.gamma)));...
f_foc_k_dk_term2 = @(z_idx)...
        (StaticParams.gamma).*(squeeze(Sol.wealth(agK_m,z_idx,:))'-sol_k(z_idx,:)).^(-StaticParams.gamma-1)...
        -StaticParams.beta*(StaticParams.P(z_idx,:)*...
         ((-StaticParams.gamma).*(1-StaticParams.delta+rate_prime(z_idx))...
         .*squeeze(c_pr(z_idx,:,:)).^(-StaticParams.gamma-1)...
         .*squeeze(c_pr_der(z_idx,:,:))))...
        +1/m+(sol_k(z_idx,:)<=y(z_idx,:)/m).*m;
        
foc_k = [f_foc_k(1);f_foc_k(2);f_foc_k(3);f_foc_k(4)].*squeeze(Sol.wealth(agK_m,:,:));
foc_k_dk = ([f_foc_k_dk_term1(1);f_foc_k_dk_term1(2);f_foc_k_dk_term1(3);f_foc_k_dk_term1(4)]...
          +[f_foc_k_dk_term2(1);f_foc_k_dk_term2(2);f_foc_k_dk_term2(3);f_foc_k_dk_term2(4)]).*squeeze(Sol.wealth(agK_m,:,:));      

% function value of the Euler equation
f = reshape(foc_k',1,numel(foc_k))';

% Jacobian of the Euler equation
if nargout>1    
    J = sparse(1:length(sol),1:length(sol),reshape(foc_k_dk',numel(foc_k_dk),1));
end
end