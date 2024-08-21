package main

import (
	"context"
	"database/sql"
	"log"

	"github.com/godror/godror"
)

var db *sql.DB

func main() {
	log.Println("start")
	var err error
	db, err = sql.Open("godror", `user="SYSTEM" password="password" connectString="localhost:1521/FREEPDB1" poolMaxSessions=3 standaloneConnection=true`)
	if err != nil {
		panic(err)
	}

	for i := 0; i < 3; i++ {
		err := enqueue("AQ_XXX_DATA")
		if err != nil {
			panic(err)
		}

		// err = dequeue("AQ_XXX_DATA")
		// if err != nil {
		// 	panic(err)
		// }
	}

}

func dequeue(dbQueue string) error {
	log.Println("dequeue")
	ctx := context.Background()
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}

	defer tx.Rollback()

	q, err := godror.NewQueue(ctx, tx, dbQueue, "QUEUE_MESSAGE_TYPE")
	if err != nil {
		return err
	}
	defer q.Close()

	msgs := make([]godror.Message, 1)
	n, err := q.Dequeue(msgs)
	if err != nil {
		return err
	}
	if n == 0 {
		log.Println("no message found")
		return nil
	}

	for _, m := range msgs[:n] {
		var data godror.Data
		if m.Object == nil {
			panic("nil")
		}
		if err := m.Object.GetAttribute(&data, "DATA"); err != nil {
			panic("object not found")
		}
		m.Object.Close()
		log.Println("dequeued: ", string(data.GetBytes()))
		err = m.Object.Close()
		if err != nil {
			return err
		}
	}

	return tx.Commit()
}

func enqueue(dbQueue string) error {
	log.Println("enqueue")
	ctx := context.Background()
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	q, err := godror.NewQueue(ctx, tx, dbQueue, "QUEUE_MESSAGE_TYPE")
	if err != nil {
		return err
	}
	defer q.Close()

	payloadObject, err := q.PayloadObjectType.NewObject()
	if err != nil {
		panic(err)
	}

	err = payloadObject.Set("data", "hello from godror")
	if err != nil {
		panic(err)
	}

	messages := []godror.Message{{
		Object: payloadObject,
	}}

	err = q.Enqueue(messages)
	if err != nil {
		panic(err)
	}

	return tx.Commit()
}
