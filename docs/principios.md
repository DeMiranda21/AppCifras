# Princípios do Projeto

**Versão:** 2.0\
**Última atualização:** 20/07/2026

## Histórico de Alterações

Versão 2.0\
• Revisão editorial completa.\
• Reorganização das seções finais.\
• Inclusão dos princípios \"Fonte Única da Verdade\" e \"Documentação
faz parte do projeto\".\
• Inclusão do princípio da Responsabilidade Única.\
• Criação da seção Contexto do Projeto.

## 1. Objetivo

Este documento estabelece os princípios permanentes que orientam todas
as decisões funcionais, arquiteturais e de desenvolvimento do projeto.
Sempre que houver dúvida sobre a implementação de uma funcionalidade ou
evolução da arquitetura, estes princípios prevalecerão.

## 2. Princípios Fundamentais

### Offline é prioridade

O aplicativo deverá funcionar integralmente sem conexão após a
sincronização.

### O usuário é dono dos seus arquivos

Os dados permanecerão em formatos acessíveis e não proprietários sempre
que possível.

### A Biblioteca Musical é o centro do sistema

O usuário trabalha com uma biblioteca, e não com arquivos isolados.

### A sincronização é um meio, não um fim

Serviços de nuvem são apenas fontes de sincronização.

### O aplicativo representa conhecimento musical

Os conceitos musicais serão modelados de forma estruturada.

### Um único modelo de dados

Toda visualização deriva do mesmo modelo interno.

### A lógica de negócio é independente da interface

As regras do sistema não dependerão das telas.

### Clareza acima da complexidade

Preferir soluções simples e legíveis.

### Modularidade e responsabilidade única

Cada componente deve possuir uma responsabilidade claramente definida.

### Evolução sem reescrita

Novas funcionalidades devem exigir o mínimo de refatoração.

### Experiência durante o culto é prioridade

Rapidez, estabilidade e poucos toques orientam a interface.

### Desempenho acima de efeitos visuais

Efeitos só quando agregarem valor.

### Arquitetura preparada para evolução

A arquitetura deve suportar crescimento incremental.

### Fonte única da verdade

Cada informação terá um documento oficial responsável por sua definição;
os demais apenas a referenciam.

### A documentação faz parte do projeto

Toda decisão permanente deverá ser refletida na documentação oficial.

## 3. Critérios para Novas Funcionalidades

Antes da inclusão de uma nova funcionalidade, deve-se verificar:\
• Resolve um problema real?\
• Mantém o aplicativo simples?\
• Preserva o funcionamento offline ou possui alternativa?\
• Respeita a arquitetura existente?\
• Reutiliza componentes existentes?\
• Melhora a experiência durante ensaios e cultos?

## 4. Contexto do Projeto

Este projeto possui dois objetivos complementares:\
• construir um aplicativo útil para músicos;\
• servir como projeto de aprendizado em engenharia de software.\
Por isso, qualidade, arquitetura e compreensão do código terão
prioridade sobre velocidade de implementação.
