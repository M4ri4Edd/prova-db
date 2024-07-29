-------------- 1ª questão A --------------
----- (a)
CREATE OR REPLACE FUNCTION INSERT_SAL() RETURNS TRIGGER AS $$
DECLARE
    orcamento_atual FLOAT;
    total_salarios FLOAT;
BEGIN
    SELECT ORCAMENTO INTO orcamento_atual
    FROM DEPARTAMENTO
    WHERE DEPTO = NEW.DEPTO;

    SELECT COALESCE(SUM(SALARIO), 0) INTO total_salarios
    FROM EMPREGADOS
    WHERE DEPTO = NEW.DEPTO;

    IF total_salarios + NEW.SALARIO > orcamento_atual THEN
        RAISE EXCEPTION 'Não foi possível registrar empregado, orçamento excedido para o departamento %', NEW.DEPTO;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER INSERT_SAL BEFORE INSERT ON EMPREGADOS FOR EACH ROW EXECUTE FUNCTION INSERT_SAL();

----- (b)

CREATE OR REPLACE FUNCTION UPDATE_SAL() RETURNS TRIGGER AS $$
DECLARE
    orcamento_atual FLOAT;
    total_salarios FLOAT;
BEGIN
    SELECT ORCAMENTO INTO orcamento_atual
    FROM DEPARTAMENTO
    WHERE DEPTO = NEW.DEPTO;

    SELECT COALESCE(SUM(SALARIO), 0) INTO total_salarios
    FROM EMPREGADOS
    WHERE DEPTO = NEW.DEPTO;

    IF total_salarios + (NEW.SALARIO - OLD.SALARIO) > orcamento_atual THEN
        RAISE EXCEPTION 'Não foi possível atualizar o salário, orçamento excedido para o departamento %', NEW.DEPTO;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER UPDATE_SAL BEFORE UPDATE ON EMPREGADOS FOR EACH ROW EXECUTE FUNCTION UPDATE_SAL();

----- (c)

CREATE OR REPLACE FUNCTION UPDATE_ORC()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT SUM(SALARIO) FROM EMPREGADOS WHERE DEPTO = NEW.DEPTO) > NEW.ORCAMENTO THEN
        RAISE EXCEPTION 'O orçamento do departamento % não é suficiente para cobrir os salários dos empregados.', NEW.DEPTO;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER UPDATE_ORC BEFORE UPDATE OF ORCAMENTO ON DEPARTAMENTO FOR EACH ROW EXECUTE FUNCTION UPDATE_ORC();

-------------- 1ª questão, alternativa b) --------------

----- (a)

CREATE OR REPLACE FUNCTION INSERT_EMP()
RETURNS TRIGGER AS $$
DECLARE
    gerente_existente VARCHAR(50);
BEGIN
    SELECT GERENTE INTO gerente_existente
    FROM EMPREGADOS
    WHERE DEPTO = NEW.DEPTO
    LIMIT 1;
    
    IF gerente_existente IS NOT NULL AND gerente_existente != NEW.GERENTE THEN
        RAISE EXCEPTION 'Todos os empregados do departamento % devem ter o mesmo gerente.', NEW.DEPTO;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER INSERT_EMP BEFORE INSERT ON EMPREGADOS FOR EACH ROW EXECUTE FUNCTION INSERT_EMP();

-----(b)


CREATE OR REPLACE FUNCTION atualizar_gerente()
RETURNS TRIGGER AS $$
DECLARE
    gerente_existente VARCHAR(50);
BEGIN
    SELECT GERENTE INTO gerente_existente
    FROM EMPREGADOS
    WHERE DEPTO = NEW.DEPTO
    LIMIT 1;

    IF NOT EXISTS (SELECT 1 FROM EMPREGADOS WHERE NOME = NEW.GERENTE AND DEPTO = NEW.DEPTO) THEN
        RAISE EXCEPTION 'O gerente % não está registrado no departamento %.', NEW.GERENTE, NEW.DEPTO;
    END IF;

    IF OLD.GERENTE IS DISTINCT FROM NEW.GERENTE THEN
        UPDATE EMPREGADOS
        SET GERENTE = NEW.GERENTE
        WHERE DEPTO = NEW.DEPTO AND GERENTE IS DISTINCT FROM NEW.GERENTE;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER UPDATE_GER BEFORE UPDATE OF GERENTE ON EMPREGADOS FOR EACH ROW EXECUTE FUNCTION atualizar_gerente();

-------------- 2ª questão, alternativa b) --------------

CREATE OR REPLACE FUNCTION questao2() 
RETURNS TRIGGER AS $$
BEGIN
    -- Verifica se já existe uma matrícula para o mesmo aluno e o mesmo horário
    IF EXISTS (
        SELECT 1
        FROM MATRICULAS m
        JOIN OFERTAS o ON m.cod_oferta = o.cod_oferta
        WHERE m.cod_aluno = NEW.cod_aluno
          AND o.horario = (
              SELECT o2.horario
              FROM OFERTAS o2
              WHERE o2.cod_oferta = NEW.cod_oferta
          )
          AND m.cod_oferta <> NEW.cod_oferta
    ) THEN
        RAISE EXCEPTION 'O aluno % já está matriculado em outra disciplina no mesmo horário.', NEW.cod_aluno;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_inserir_mat2 BEFORE INSERT ON matriculas FOR EACH ROW EXECUTE PROCEDURE questao2();
