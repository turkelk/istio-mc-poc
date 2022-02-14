using System.Threading.Tasks;
using Quantic.Core;
using Transfers.API.Model;
using Transfers.API.Query;

namespace Transfers.API.Commands
{
    public class DoTransferHandler : ICommandHandler<DoTransfer>
    {
        private readonly IQueryHandler<GetAccountByNumber, Account> getAccountByNumberHandler;
        private readonly IQueryHandler<GetCustomerByCif, Customer> getCustomerByCifHandler;
        private readonly IQueryHandler<GetCustomerLimit, Limit> getCustomerLimitHandler;

        public DoTransferHandler(IQueryHandler<GetAccountByNumber, Account> getAccountByNumberHandler,
            IQueryHandler<GetCustomerByCif, Customer> getCustomerByCifHandler,
            IQueryHandler<GetCustomerLimit, Limit> getCustomerLimitHandler)
        {
            this.getAccountByNumberHandler = getAccountByNumberHandler;
            this.getCustomerByCifHandler = getCustomerByCifHandler;
            this.getCustomerLimitHandler = getCustomerLimitHandler;
        }

        public async Task<CommandResult> Handle(DoTransfer command, RequestContext context)
        {
            var getAccount = await getAccountByNumberHandler.Handle(new GetAccountByNumber(command.Sender), context);
            if (getAccount.HasError)
                return CommandResult.WithError(Msg.GetAccountError, "get from account error");

            var fromAccount = getAccount.Result;

            getAccount = await getAccountByNumberHandler.Handle(new GetAccountByNumber(command.Receiver), context);
            if (getAccount.HasError)
                return CommandResult.WithError(Msg.GetAccountError, "get to account error");

            var toAccount = getAccount.Result;

            var getLimit = await getCustomerLimitHandler.Handle(new GetCustomerLimit("1234"), context);
            if (getLimit.HasError)
                return CommandResult.WithError(getLimit.Errors);

            return CommandResult.Success;
        }
    }
    public class DoTransfer : ICommand
    {
        public DoTransfer(string sender, string receiver, double amount, string currency)
        {
            Sender = sender;
            Receiver = receiver;
            Amount = amount;
            Currency = currency;
        }

        public string Sender { get; }
        public string Receiver { get; }
        public double Amount { get; }
        public string Currency { get; }
    }
}
