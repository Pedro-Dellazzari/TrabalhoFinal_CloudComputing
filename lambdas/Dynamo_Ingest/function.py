from baseDAO import BaseDAO


def lambda_handler(event, context):
    detail = event.get('detail', {})
    item = {
        "pedido": str(detail.get('pedido')),
        "status": detail.get('status'),
        "cliente": detail.get('cliente'),
        "time": event.get('time')
    }

    dao = BaseDAO('eventos-pizzaria')

    response = dao.put_item(item)
    print(response)

    return True