--- TRATA DADOS PARA POWER BI

update		clientes
set			data_inclusao =	left(data_inclusao, len(data_inclusao) - 4)

alter table	clientes add UF CHAR(2) 
alter table	clientes add IDADE INT 

update		clientes
set			UF	=	RIGHT(ENDERECO, 2)

update		clientes
set			idade = CONVERT(INT, DATEDIFF(D, DATA_NASCIMENTO, GETDATE()) / 365.25)

update		propostas_credito
set			data_entrada_proposta =	left(data_entrada_proposta, len(data_entrada_proposta) - 4)

alter table	propostas_credito add MES_PROPOSTA AS	CASE
														WHEN	MONTH(data_entrada_proposta) = 1
														THEN	'janeiro'
														WHEN	MONTH(data_entrada_proposta) = 2
														THEN	'fevereiro'
														WHEN	MONTH(data_entrada_proposta) = 3
														THEN	'março'
														WHEN	MONTH(data_entrada_proposta) = 4
														THEN	'abril'
														WHEN	MONTH(data_entrada_proposta) = 5
														THEN	'maio'
														WHEN	MONTH(data_entrada_proposta) = 6
														THEN	'junho'
														WHEN	MONTH(data_entrada_proposta) = 7
														THEN	'julho'
														WHEN	MONTH(data_entrada_proposta) = 8
														THEN	'agosto'
														WHEN	MONTH(data_entrada_proposta) = 9
														THEN	'setembro'
														WHEN	MONTH(data_entrada_proposta) = 10
														THEN	'outubro'
														WHEN	MONTH(data_entrada_proposta) = 11
														THEN	'novembro'
														WHEN	MONTH(data_entrada_proposta) = 12
														THEN	'dezembro'
													END
,			ANO_PROPOSTA AS YEAR(data_entrada_proposta)

alter table	propostas_credito	add UF CHAR(2)

UPDATE		A
SET			UF		=	B.UF

FROM		propostas_credito	A

LEFT JOIN	clientes	B
ON			A.cod_cliente	=	B.cod_cliente


update		transacoes
set			data_transacao	 =	left(data_transacao, len(data_transacao) - 4)

alter table	transacoes	add UF CHAR(2)
alter table	transacoes	add transacoes_resumo as case
													when	nome_transacao like '%pix%'
													then	'PIX'
													else	'Outros'
												end
UPDATE		A
SET			UF		=	B.UF

FROM		transacoes	A

LEFT JOIN	clientes	B
ON			A.num_conta	=	B.cod_cliente

DELETE		transacoes
WHERE		num_conta = 528

-------------------------------------------------- APURAÇÃO TRANSAÇÕES POR FAIXA ETÁRIA

USE			BANVIC

IF (OBJECT_ID('TEMPDB..#ANALISE_TRANSAC_IDADE') IS NOT NULL)
	BEGIN
		DROP TABLE #ANALISE_TRANSAC_IDADE
	END

SELECT		OPERACAO
,			[QTD_16 - 25]	=	SUM([16 - 25])
,			[VLR_16 - 25]	=	FORMAT(SUM([16 - 25 2]) / 1000, 'N', 'PT-BR')
,			[QTD_26 - 35]	=	SUM([26 - 35])
,			[VLR_26 - 35]	=	FORMAT(SUM([26 - 35 2]) / 1000, 'N', 'PT-BR')
,			[QTD_36 - 45]	=	SUM([36 - 45])
,			[VLR_36 - 45]	=	FORMAT(SUM([36 - 45 2]) / 1000, 'N', 'PT-BR')
,			[QTD_46 - 55]	=	SUM([46 - 55])
,			[VLR_46 - 55]	=	FORMAT(SUM([46 - 55 2]) / 1000, 'N', 'PT-BR')
,			[QTD_56 - 69]	=	SUM([56 - 69])
,			[VLR_56 - 69]	=	FORMAT(SUM([56 - 69 2]) / 1000, 'N', 'PT-BR')
,			[QTD_70 + ]		=	SUM([70 + ])
,			[VLR_70 + ]		=	FORMAT(SUM([70 +  2]) / 1000, 'N', 'PT-BR')

,			QTD_TOTAIS		=	SUM([16 - 25]) + SUM([26 - 35]) + SUM([36 - 45]) + SUM([46 - 55]) + SUM([56 - 69]) + SUM([70 + ])
,			VLR_TOTAIS		=	FORMAT	(	SUM([16 - 25 2]) + SUM([26 - 35 2]) + SUM([36 - 45 2]) + SUM([46 - 55 2]) + SUM([56 - 69 2]) + SUM([70 +  2]), 'N', 'PT-BR')

INTO		#ANALISE_TRANSAC_IDADE

FROM		(
			SELECT		[OPERACAO]			=	TP_OPERAC_RESU
			,			[FAIXA_ETARIA]		=	CASE
													WHEN	IDADE	BETWEEN 16 AND 25
													THEN	'16 - 25'
													WHEN	IDADE	BETWEEN 26 AND 35
													THEN	'26 - 35'
													WHEN	IDADE	BETWEEN 36 AND 45
													THEN	'36 - 45'
													WHEN	IDADE	BETWEEN 46 AND 55
													THEN	'46 - 55'
													WHEN	IDADE	BETWEEN 56 AND 69
													THEN	'56 - 69'
													ELSE	'70 + '
												END
			,			[FAIXA_ETARIA_B]	=	CASE
													WHEN	IDADE	BETWEEN 16 AND 25
													THEN	'16 - 25 2'
													WHEN	IDADE	BETWEEN 26 AND 35
													THEN	'26 - 35 2'
													WHEN	IDADE	BETWEEN 36 AND 45
													THEN	'36 - 45 2'
													WHEN	IDADE	BETWEEN 46 AND 55
													THEN	'46 - 55 2'
													WHEN	IDADE	BETWEEN 56 AND 69
													THEN	'56 - 69 2'
													ELSE	'70 +  2'
												END
			,			[QTDE]				=	SUM(QTDE)
			,			[VLR]				=	SUM(VLR_TRANSAC)

			FROM		(
						SELECT DISTINCT	A.*
						,				[IDADE]			=	CONVERT(INT, DATEDIFF(D, DT_NASCIMENTO, GETDATE()) / 365.25)
						FROM			(
										SELECT			[ANO_MES]			=	FORMAT(convert(date, LEFT(A.DATA_TRANSACAO, 10)), 'yyyyMM')
										,				[DT_TRANSAC]		=	convert(datetime, LEFT(A.DATA_TRANSACAO, 19), 102)
										,				[DIA_SEMANA]		=	DATEPART(DW, convert(datetime, LEFT(A.DATA_TRANSACAO, 19), 102))
										,				[NM_DIA_SEMANA]		=	DATENAME ( WEEKDAY , convert(datetime, LEFT(A.DATA_TRANSACAO, 19), 102) )
										,				[AGENCIA]			=	C.cod_agencia
										,				B.num_conta
										,				[DT_NASCIMENTO]		=	D.data_nascimento
										,				[ID_TRANSAC]		=	A.cod_transacao
										,				[TP_OPERAC]			=	A.nome_transacao
										,				[TP_OPERAC_RESU]	=	CASE
																					WHEN	A.NOME_TRANSACAO	IN	(	'TED - RECEBIDO'
																													,	'TRANSFERÊNCIA ENTRE CC - CRÉDITO'
																													,	'DOC - RECEBIDO'
																													)
																					THEN	'Transf. - Recebidas'
																					WHEN	A.NOME_TRANSACAO	IN	(	'DOC - REALIZADO'
																													,	'TRANSFERÊNCIA ENTRE CC - DÉBITO'
																													,	'TED - REALIZADO'
																													)
																					THEN	'Transf. - Enviadas'
																					WHEN	A.nome_transacao	=	'Pix - Recebido'
																					THEN	'PIX - Recebidas'
																					WHEN	A.nome_transacao	=	'Pix - Realizado'
																					THEN	'PIX - Enviadas'
																					WHEN	A.nome_transacao	=	'SAQUE'
																					THEN	'Saques'
																					WHEN	A.nome_transacao	=	'Pix Saque'
																					THEN	'PIX Saque'
																					WHEN	A.nome_transacao	IN	('Compra Crédito', 'Compra Débito')
																					THEN	'Compras'
																					ELSE	A.nome_transacao
																				END
										,				QTDE				=	1
										,				VLR_TRANSAC			=	A.valor_transacao
										,				c.TIPO_AGENCIA
										FROM			[dbo].[transacoes]		A

											LEFT JOIN	contas					B
											ON			A.num_conta	=	B.num_conta

											left join	agencias				c
											on			b.cod_agencia	=	c.cod_agencia

											LEFT JOIN	CLIENTES				D
											ON			B.num_conta		=	D.cod_cliente
										)	A
						)	A
		
			GROUP BY	TP_OPERAC_RESU
			,			CASE
							WHEN	IDADE	BETWEEN 16 AND 25
							THEN	'16 - 25'
							WHEN	IDADE	BETWEEN 26 AND 35
							THEN	'26 - 35'
							WHEN	IDADE	BETWEEN 36 AND 45
							THEN	'36 - 45'
							WHEN	IDADE	BETWEEN 46 AND 55
							THEN	'46 - 55'
							WHEN	IDADE	BETWEEN 56 AND 69
							THEN	'56 - 69'
							ELSE	'70 + '
						END
			,			CASE
							WHEN	IDADE	BETWEEN 16 AND 25
							THEN	'16 - 25 2'
							WHEN	IDADE	BETWEEN 26 AND 35
							THEN	'26 - 35 2'
							WHEN	IDADE	BETWEEN 36 AND 45
							THEN	'36 - 45 2'
							WHEN	IDADE	BETWEEN 46 AND 55
							THEN	'46 - 55 2'
							WHEN	IDADE	BETWEEN 56 AND 69
							THEN	'56 - 69 2'
							ELSE	'70 +  2'
						END
			)	A

	PIVOT	(
			SUM(QTDE) FOR FAIXA_ETARIA IN ([16 - 25], [26 - 35], [36 - 45], [46 - 55], [56 - 69], [70 + ] )
			)	B

	PIVOT	(
			SUM(VLR) FOR [FAIXA_ETARIA_B] IN ([16 - 25 2], [26 - 35 2], [36 - 45 2], [46 - 55 2], [56 - 69 2], [70 +  2] )
			)	C

GROUP BY	OPERACAO
WITH ROLLUP
ORDER BY	CASE
				WHEN	OPERACAO	=	'PIX - Enviadas'
				THEN	1
				WHEN	OPERACAO	=	'PIX Saque'
				THEN	2
				WHEN	OPERACAO	=	'Saques'
				THEN	3
				WHEN	OPERACAO	=	'Pagamento de boleto'
				THEN	4
				WHEN	OPERACAO	=	'Transf. - Enviadas'
				THEN	5
				WHEN	OPERACAO	=	'Compras'
				THEN	6
				WHEN	OPERACAO	=	'PIX - Recebidas'
				THEN	7
				WHEN	OPERACAO	=	'Depósito em espécie'
				THEN	8
				WHEN	OPERACAO	=	'Estorno de Debito'
				THEN	9
				ELSE	10
			END

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------- APURAÇÃO CAMPANHA CRÉDITO CAMPEÃO ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--------------- CALCULA OBJETIVO
IF (OBJECT_ID('TEMPDB..#OBJETIVO') IS NOT NULL)
	BEGIN
		DROP TABLE #OBJETIVO
	END

SELECT			ANO				=	YEAR(convert(date, LEFT(A.data_entrada_proposta, 10)))
,				FUNCIONARIO		=	A.cod_colaborador
,				NM_FUNCIONARIO	=	CONCAT(D.primeiro_nome, ' ', D.ultimo_nome)
,				INDICADOR		=	CONVERT(VARCHAR(30), 'CREDITO')
,				OBJETIVO		=	SUM(A.valor_financiamento) * 1.1

INTO			#OBJETIVO

FROM			[dbo].[propostas_credito]	A

	LEFT JOIN	contas						B
	ON			A.cod_cliente	=	B.num_conta

	left join	agencias					c
	on			b.cod_agencia	=	c.cod_agencia

	LEFT JOIN	colaboradores			D
	ON			A.cod_colaborador	=	D.cod_colaborador

WHERE			YEAR(convert(date, LEFT(A.data_entrada_proposta, 10))) = 2021

GROUP BY		YEAR(convert(date, LEFT(A.data_entrada_proposta, 10)))
,				A.cod_colaborador
,				CONCAT(D.primeiro_nome, ' ', D.ultimo_nome)


INSERT INTO		#OBJETIVO

SELECT			ANO				=	YEAR(convert(date, LEFT(A.data_entrada_proposta, 10)))
,				FUNCIONARIO		=	A.cod_colaborador
,				NM_FUNCIONARIO	=	CONCAT(D.primeiro_nome, ' ', D.ultimo_nome)
,				INDICADOR		=	'FATURAMENTO LIQUIDO'
,				OBJETIVO		=	SUM((quantidade_parcelas * valor_prestacao) - A.valor_financiamento) * 1.1

FROM			[dbo].[propostas_credito]	A

	LEFT JOIN	contas						B
	ON			A.cod_cliente	=	B.num_conta

	left join	agencias					c
	on			b.cod_agencia	=	c.cod_agencia

	LEFT JOIN	colaboradores			D
	ON			A.cod_colaborador	=	D.cod_colaborador

WHERE			YEAR(convert(date, LEFT(A.data_entrada_proposta, 10))) = 2021

GROUP BY		YEAR(convert(date, LEFT(A.data_entrada_proposta, 10)))
,				A.cod_colaborador
,				CONCAT(D.primeiro_nome, ' ', D.ultimo_nome)


--------------- CALCULA REALIZADO
IF (OBJECT_ID('TEMPDB..#REALIZADO') IS NOT NULL)
	BEGIN
		DROP TABLE #REALIZADO
	END

SELECT			ANO				=	YEAR(convert(date, LEFT(A.data_entrada_proposta, 10)))
,				FUNCIONARIO		=	A.cod_colaborador
,				NM_FUNCIONARIO	=	CONCAT(D.primeiro_nome, ' ', D.ultimo_nome)
,				INDICADOR		=	CONVERT(VARCHAR(30), 'CREDITO')
,				QTDE			=	COUNT(A.COD_PROPOSTA)
,				REALIZADO		=	SUM(A.valor_financiamento)

INTO			#REALIZADO

FROM			[dbo].[propostas_credito]	A

	LEFT JOIN	contas						B
	ON			A.cod_cliente	=	B.num_conta

	left join	agencias					c
	on			b.cod_agencia	=	c.cod_agencia

	LEFT JOIN	colaboradores			D
	ON			A.cod_colaborador	=	D.cod_colaborador

WHERE			YEAR(convert(date, LEFT(A.data_entrada_proposta, 10))) = 2022
GROUP BY		YEAR(convert(date, LEFT(A.data_entrada_proposta, 10)))
,				A.cod_colaborador
,				CONCAT(D.primeiro_nome, ' ', D.ultimo_nome)

INSERT INTO		#REALIZADO
SELECT			ANO				=	YEAR(convert(date, LEFT(A.data_entrada_proposta, 10)))
,				FUNCIONARIO		=	A.cod_colaborador
,				NM_FUNCIONARIO	=	CONCAT(D.primeiro_nome, ' ', D.ultimo_nome)
,				INDICADOR		=	'FATURAMENTO LIQUIDO'
,				QTDE			=	COUNT(A.COD_PROPOSTA)
,				REALIZADO		=	SUM((quantidade_parcelas * valor_prestacao) - A.valor_financiamento)

FROM			[dbo].[propostas_credito]	A

	LEFT JOIN	contas						B
	ON			A.cod_cliente	=	B.num_conta

	left join	agencias					c
	on			b.cod_agencia	=	c.cod_agencia

	LEFT JOIN	colaboradores			D
	ON			A.cod_colaborador	=	D.cod_colaborador

WHERE			YEAR(convert(date, LEFT(A.data_entrada_proposta, 10))) = 2022
GROUP BY		YEAR(convert(date, LEFT(A.data_entrada_proposta, 10)))
,				A.cod_colaborador
,				CONCAT(D.primeiro_nome, ' ', D.ultimo_nome)


--------------- CALCULA PERFORMANCE
IF (OBJECT_ID('TEMPDB..#PERFORMANCE') IS NOT NULL)
	BEGIN
		DROP TABLE #PERFORMANCE
	END

SELECT			B.ANO, B.FUNCIONARIO, B.NM_FUNCIONARIO
,				A.INDICADOR
,				[INDICADOR_B]	=	CONCAT(A.INDICADOR, '_B')	
,				[INDICADOR_C]	=	CONCAT(A.INDICADOR, '_C')
,				[INDICADOR_D]	=	CONCAT(A.INDICADOR, '_D')
,				[INDICADOR_E]	=	CONCAT(A.INDICADOR, '_E')
,				A.OBJETIVO, B.REALIZADO
,				[PERC]		=	B.REALIZADO	/	A.OBJETIVO
,				[SALDO]		=	IIF(B.REALIZADO	>= A.OBJETIVO, 0, B.REALIZADO - A.OBJETIVO)

INTO			#PERFORMANCE

FROM			#OBJETIVO	A
	
	INNER JOIN	#REALIZADO	B
	ON			A.FUNCIONARIO	=	B.FUNCIONARIO
	AND			A.INDICADOR		=	B.INDICADOR


--------------- INICIA APURACAO
IF (OBJECT_ID('TEMPDB..#APURADO') IS NOT NULL)
	BEGIN
		DROP TABLE #APURADO
	END

SELECT			ANO, FUNCIONARIO, NM_FUNCIONARIO
, 				[ELEGIVEL]		=	SUM(IIF([CREDITO_C] >= 1, 1, 0))
,				[OBJETIVO]		=	SUM([CREDITO])
,				[REALIZADO]		=	SUM([CREDITO_B])
,				[PERC]			=	SUM([CREDITO_C])
,				[SALDO]			=	SUM([CREDITO_D])
,				[FATURAMENTO]	=	SUM([FATURAMENTO LIQUIDO_B])

INTO			#APURADO

FROM			#PERFORMANCE	A

	PIVOT		(
				SUM(OBJETIVO) FOR INDICADOR IN ([CREDITO])
				)				B

	PIVOT		(
				SUM(REALIZADO) FOR INDICADOR_B IN ([CREDITO_B], [FATURAMENTO LIQUIDO_B])
				)				C

	PIVOT		(
				SUM([PERC]) FOR INDICADOR_C IN ([CREDITO_C])
				)				D

	PIVOT		(
				SUM([SALDO]) FOR INDICADOR_D IN ([CREDITO_D])
				)				E

GROUP BY		ANO, FUNCIONARIO, NM_FUNCIONARIO


--------------- RANKEADO
IF (OBJECT_ID('TEMPDB..#FINAL') IS NOT NULL)
	BEGIN
		DROP TABLE #FINAL
	END

SELECT			ANO, FUNCIONARIO, NM_FUNCIONARIO
,				RK			=	COUNT(FUNCIONARIO) OVER ( PARTITION BY ANO ORDER BY ELEGIVEL DESC, REALIZADO DESC, FATURAMENTO DESC)
,				ELEGIVEL	=	format(ELEGIVEL	, 'n', 'pt-br')
,				OBJETIVO	=	format(OBJETIVO	, 'n', 'pt-br')
,				REALIZADO	=	format(REALIZADO	, 'n', 'pt-br')
,				PERC		=	format(PERC		, 'p', 'pt-br')
,				SALDO		=	format(SALDO		, 'n', 'pt-br')
,				FATURAMENTO	=	format(FATURAMENTO	, 'n', 'pt-br')

INTO			#FINAL

FROM			#APURADO

SELECT			*
FROM			#FINAL