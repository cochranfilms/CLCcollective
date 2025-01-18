let mutation = """
            mutation CreateInvoice($input: InvoiceCreateInput!) {
                invoiceCreate(input: $input) {
                    didSucceed
                    inputErrors {
                        message
                        code
                        path
                    }
                    invoice {
                        id
                        viewUrl
                        status
                        customer {
                            id
                            name
                        }
                        items {
                            product {
                                id
                                name
                            }
                            quantity
                            unitPrice
                            total
                        }
                    }
                }
            }
            """ 