using System.Threading.Tasks;

namespace Retail.API.Controllers
{
    public class DoTransferRequest
    {
        public string Sender { get; set; }
        public string Receiver { get; set; }
        public double Amount { get; set; }
        public string Currency { get; set; }        
    }
}
